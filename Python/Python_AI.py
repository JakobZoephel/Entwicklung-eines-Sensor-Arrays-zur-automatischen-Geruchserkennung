'''
@author: Jakob
'''

 
import os

#os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 
#os.environ['CUDA_VISIBLE_DEVICES'] = '' 

# zumindest auf Arch Linux
os.environ['XLA_FLAGS'] = '--xla_gpu_cuda_data_dir=/opt/cuda'
# nicht unbedingt nötig
os.environ['LD_LIBRARY_PATH'] = '$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/python3.8/site-packages/tensorrt/'

os.environ['TF_FORCE_GPU_ALLOW_GROWTH'] = 'true'
import tensorflow as tf
gpus = tf.config.list_physical_devices('GPU')
if gpus:
  try:
    for gpu in gpus:
      tf.config.experimental.set_memory_growth(gpu, True)
  except RuntimeError as e:
    print(e)

if gpus:
  # VRAM Limit, in MBs
  try:
    tf.config.set_logical_device_configuration(
        gpus[0],
        [tf.config.LogicalDeviceConfiguration(memory_limit=2000)])
    #logical_gpus = tf.config.list_logical_devices('GPU')
    #print(len(gpus), "Physical GPUs,", len(logical_gpus), "Logical GPUs")
  except RuntimeError as e:
    print(e)

print()
print()

import keras_tuner as kt
import numpy as np
import random
from Encoder_legacy import loadArray
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import pandas as pd

with open('existingLabels') as f:
  CLASS_NAMES = f.read().split('\n')

CLASS_NAMES.remove('')
print(CLASS_NAMES)

EPOCHS = 8
LOAD_MODEL = False
SAVE_MODEL = False
MODEL_NAME = 'MyFirstModel'
# ein HyperModel trainieren
TUNER = True


def norm(value, start1, stop1, start2, stop2):
  return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))


def load_data(softmax=False, test_size=0.1, one_hot=True, print_shapes=False):

  X = loadArray('examples')

  if softmax:

    X = np.array(X)
    
    X_max_values = [0]*X.shape[1]
    for i in range(X.shape[0]):
      for j in range(X.shape[1]):
        if X_max_values[j] < X[i][j]:
          X_max_values[j] = X[i][j]
    
    for i in range(X.shape[0]):
      for j in range(X.shape[1]):
        X[i][j] =  norm(X[i][j], 0, X_max_values[j], 0, 100);
    

    #for i in range(X.shape[0]):
   #   X[i] = tf.nn.softmax(X[i]).numpy()
    X = list(X)

  with open('label') as f:
    Y_names = f.read().split('\n')
  Y_names.remove('')

  Y = []
  for label in Y_names:
    if not one_hot:
      Y.append(CLASS_NAMES.index(label))
      continue
    one_hot = [0] * len(CLASS_NAMES)
    one_hot[CLASS_NAMES.index(label)] = 1
    Y.append(one_hot)

  if test_size <= 0:
    assert len(X) == len(Y)
    p = np.random.permutation(len(X))
    X = np.array(X, dtype=float)
    X = X[p]
    Y = np.array(Y, dtype=float)
    Y = Y[p]
    if print_shapes:
      print('shapes:')
      print(X.shape)
      print(Y.shape)
    return X, Y

  x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size=test_size)

  x_train = np.array(x_train, dtype=float)
  y_train = np.array(y_train, dtype=float)

  assert len(x_train) == len(y_train)
  p = np.random.permutation(len(x_train))
  x_train = x_train[p]
  y_train = y_train[p]

  x_test = np.array(x_test)
  y_test = np.array(y_test)

  if print_shapes:
    print('train shapes:')
    print(x_train.shape)
    print(y_train.shape)
    print()
    print('test shapes:')
    print(x_test.shape)
    print(y_test.shape)
    print('\n')

  return x_train, y_train, x_test, y_test


class Model(tf.keras.Model):

  def __init__(self):
    super().__init__()
    self.linear0 = tf.keras.layers.Dense(120, activation='relu')
    self.linear1 = tf.keras.layers.Dense(35, activation='relu')
    self.out = tf.keras.layers.Dense(len(CLASS_NAMES), activation='softmax')

  def call(self, x):
    x = self.linear0(x)
    x = self.linear1(x)
    return self.out(x)

class MyHyperModel(kt.HyperModel):


  def build(self, hp):
     
    # Das Model wird nach jedem Training automatisch neu erstellt, allerdings mit neuen Hyper-Parametern.
    # Erstellt man dabei nicht jedes Mal auch die "static" bzw. "const." Layers neu,
    # kommt es zu Fehlern, da die In/Out Dimensionen der Layer nicht passen.

    hyperModel = tf.keras.Sequential()

    for i in range(hp.Int('num_layers', min_value=1, max_value=4, step=1)):
        hyperModel.add(tf.keras.layers.Dense(
                      units=hp.Int('linear_units_' + str(i),
                      min_value=32,
                      max_value=512,
                      step=32),
                      activation= hp.Choice('activation_' +  str(i), values=['relu', 'sigmoid', 'tanh'])))

    hyperModel.add(tf.keras.layers.Dense(len(CLASS_NAMES), activation='softmax'))

    # 0.01, 0.001, oder 0.0001
    hp_learning_rate = hp.Choice('learning_rate', values=[1e-2, 1e-3, 1e-4])

    hyperModel.compile(
                  optimizer=tf.keras.optimizers.Adam(learning_rate=hp_learning_rate),
                  loss='binary_crossentropy',
                  metrics=['accuracy']
                  )

    return hyperModel 
  

  def fit(self, hp, model, *args, **kwargs):
      return model.fit(
          *args,
          batch_size=hp.Int("batch_size", min_value=2, max_value=16, step=2),
          **kwargs,
      )
  
def hypertuning():

  x_train, y_train, x_test, y_test = load_data(print_shapes=True)

  tuner = kt.Hyperband(
                      MyHyperModel(),
                      objective='val_loss',
                      max_epochs=15,
                      project_name='Checkpoints-Tuner',
                      )


  # wenn sich die accuracy auf den Trainingsdaten nach patience Epochen nicht ändert, Training beenden
  stop_early = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=8)

  tuner.search(
    x_train, 
    y_train, 
    epochs=30, 
    validation_data=(x_test, y_test),
    callbacks=[stop_early],
    ) 
  # die besten Hyperparameter
  best_hps=tuner.get_best_hyperparameters()[0]
  # beste Anzahl an Epochen finden
  model = tuner.hypermodel.build(best_hps)
  history = model.fit(
    x_train, 
    y_train, 
    epochs=20, 
    validation_data=(x_test, y_test),
    )

  val_acc_per_epoch = history.history['val_loss']
  best_epoch = val_acc_per_epoch.index(max(val_acc_per_epoch)) + 1
  print('Beste Epoche: %d' % (best_epoch,))


  # schlussendlich mit den ganzen Hyperparametern + Epochenanzahl trainieren
  hypermodel = tuner.hypermodel.build(best_hps)
  hypermodel.fit(
    x_train, 
    y_train, 
    epochs=best_epoch, 
    validation_data=(x_test, y_test),
)
  eval_result = hypermodel.evaluate(x_test, y_test)
  print("[test loss, test accuracy]:", eval_result)
  hypermodel.save('MyHyperModel_0')


def test(data, verb=1):

  test_example = np.expand_dims(np.array(data), axis=(0))
  predictions = model.predict(test_example, verbose=verb)
  score = predictions[0]
  result = np.argmax(score)
  return result, 100 * np.max(score)


def get_most_components(_data, plot=False, y=None, y_names=None):

    train_features = _data.copy()
    feature_names = ['MQ2', 'MQ3', 'MQ4', 'MQ5', 'MQ6', 'MQ7', 'MQ8', 'MQ9', 'MQ131', 'MQ135', 'MQ136',
                'MQ137', 'MQ138', 'VOC', 'O2', 'CO2', 'PM2.5', 'PM10', 'Luftfeuchtigkeit']

    print(train_features.shape)
    pca = PCA().fit(train_features)
    X_pc = pca.transform(train_features)

    # Anzahl der Komponenten
    n_pcs = pca.components_.shape[0]
    # die Indexe der wichtigsten Komponenten bekommen
    most_important = [np.abs(pca.components_[i]).argmax() for i in range(n_pcs)]
    # nun die Namen
    most_important_names = [feature_names[most_important[i]] for i in range(n_pcs)]

    dic = {'PC{}'.format(i): most_important_names[i] + ' ' + "{:.8f}".format(pca.explained_variance_ratio_[i]) for i in range(n_pcs)}
    df = pd.DataFrame(sorted(dic.items()))
    print(df)

    if plot:
      plt.figure(figsize=(8,6))
      # eine colormap von https://matplotlib.org/stable/tutorials/colors/colormaps.html
      plot = plt.scatter(X_pc[:,0], X_pc[:,1], c=y, cmap='Dark2')
      plt.legend(handles=plot.legend_elements()[0], labels=y_names)
      plt.xlabel(most_important_names[0])
      plt.ylabel(most_important_names[1])
      plt.title("Die ersten zwei Hauptkomponenten")
      plt.savefig('Wichtigkeit der Sensoren 2D.jpeg')
      plt.show()

      fig = plt.figure(figsize=(10,8))
      ax = fig.add_subplot(projection='3d')
      ax.scatter(X_pc[:,1], X_pc[:,2], X_pc[:,3], c=y, cmap='Dark2', s=60)
      plt.legend(handles=plot.legend_elements()[0], labels=y_names)
      ax.set_xlabel(most_important_names[0])
      ax.set_ylabel(most_important_names[1])
      ax.set_zlabel(most_important_names[2])
      ax.set_title("Die ersten drei Hauptkomponenten")
      plt.savefig('Wichtigkeit der Sensoren 3D.jpeg')
      plt.show()

if __name__ == '__main__':

  if TUNER:
    hypertuning()

  if LOAD_MODEL:
    model = tf.keras.models.load_model('models/' + MODEL_NAME, custom_objects={"Model": Model})
  else:
    model = Model()
    

  x_train, y_train, x_test, y_test = load_data(print_shapes=True)
  
  model.compile(
    optimizer='adam',
    loss='binary_crossentropy',
    metrics=['accuracy']
  )

  #print(tf.config.list_physical_devices('GPU'))
  #print(tf.test.is_built_with_cuda())

  model.fit(
    x_train,
    y_train,
    epochs=EPOCHS,
    validation_data=(x_test, y_test),
    batch_size=1
  )

  knn = KNeighborsClassifier(n_neighbors=1).fit(x_train, y_train)
  accuracy = knn.score(x_test, y_test)
  print('KNN:', accuracy)

  dtree_model = DecisionTreeClassifier(max_depth=2).fit(x_train, y_train)
  accuracy = dtree_model.score(x_test, y_test)
  print('Tree:', accuracy)

  X, Y = load_data(test_size=0, one_hot=False, softmax=True)
  get_most_components(X, plot=True, y=Y, y_names=CLASS_NAMES)

  # einfach ein Test, ob ich die PCA auch richtig gemacht habe
  X = [[0, 1, 2, 3, 4, 5], 
      [6, 1, 2, 3, 4, 5], 
      [0, 1, 2, 3, 4, 11]]
  X = np.array(X)
  get_most_components(X, plot=False,)

  x_train, y_train, x_test, y_test = load_data(one_hot=False)
  svm_model_linear = SVC(kernel='linear').fit(x_train, y_train)
  accuracy = svm_model_linear.score(x_test, y_test)
  print('SVM:', accuracy)

  if SAVE_MODEL:
    model.save('models/' + MODEL_NAME)

  