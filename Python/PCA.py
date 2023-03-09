from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
cmap, norm = mcolors.from_levels_and_colors([0, 1, 2, 15], ['red', 'green', 'blue'])
cmap = 'Dark2'
import pandas as pd
import numpy as np
from Encoder import loadArray
import tensorflow as tf

def get_most_components(_data, softmax=False, plot=False, y=None, y_names=None):

    train_features = _data.copy()

    if softmax:
        for i in range(train_features.shape[0]):
            train_features[i] = tf.nn.softmax(train_features[i]).numpy()


    feature_names = ['MQ2', 'MQ3', 'MQ4', 'MQ5', 'MQ6', 'MQ7', 'MQ8', 'MQ9', 'MQ135', 'MQ136',
                'MQ137', 'MQ138', 'MG811', 'VOC', 'O2', 'CO2', 'PM2.5', 'PM10', 'Temperatur', 'Luftfeuchtigkeit']

    print(train_features.shape)
    print(len(feature_names))
    pca = PCA().fit(train_features)
    X_pc = pca.transform(train_features)

    # Anzahl der Komponenten
    n_pcs = pca.components_.shape[0]
    # die Indexe der wichtigsten Komponenten bekommen
    most_important = [np.abs(pca.components_[i]).argmax() for i in range(n_pcs)]
    # nun die Namen
    most_important_names = [feature_names[most_important[i]] for i in range(n_pcs)]

    dic = {'PC{}'.format(i): most_important_names[i] + ' ' + "{:.4f}".format(pca.explained_variance_ratio_[i]) for i in range(n_pcs)}
    df = pd.DataFrame(sorted(dic.items()))
    print(df)

    if plot:
        plt.figure(figsize=(8,6))
        plot = plt.scatter(X_pc[:,0], X_pc[:,1], c=y, cmap=cmap, norm=norm)
        plt.legend(handles=plot.legend_elements()[0], labels=y_names)
        plt.xlabel(most_important_names[0])
        plt.ylabel(most_important_names[1])
        plt.title("Die ersten zwei principal components")
        plt.show()

        fig = plt.figure(figsize=(10,8))
        ax = fig.add_subplot(projection='3d')
        ax.scatter(X_pc[:,1], X_pc[:,2], X_pc[:,3], c=y, alpha=0.8, cmap=cmap, norm=norm, s=60)
        ax.set_xlabel(most_important_names[0])
        ax.set_ylabel(most_important_names[1])
        ax.set_zlabel(most_important_names[2])
        ax.set_title("Die ersten drei principal components")
        plt.show()


if __name__ == '__main__':
    train_features =  np.array(loadArray('examples'))


    with open('existingLabels') as f:
        CLASS_NAMES = f.read().split('\n')

    CLASS_NAMES.remove('')

    with open('label') as f:
        Y_names = f.read().split('\n')
    Y_names.remove('')

    Y = []
    for label in Y_names:
        Y.append(CLASS_NAMES.index(label))

    get_most_components(train_features, plot=True, y=Y, y_names=CLASS_NAMES)
    print()
    print()

    # get_most_components(train_features.T)

    my_list =  [[1,3,3,4,5,6,7,2,9],
                [1,1,3,4,5,6,7,84,9],
                [1,6,3,4,5,6,7,2,9],
                [1,4,3,4,5,6,7,82345,9],
                ]
    my_list = np.array(my_list, dtype=float)
    get_most_components(my_list)