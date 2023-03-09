# ähnlich wie die Processing Funktion, nur in Python
def loadArray(fileName):

    with open(fileName) as f:
        strings = f.read().split('\n')

    strings.remove('')

    for i in range(len(strings)):
        strings[i] = float(strings[i])

    arr_len = int(strings[0])
    sub_arr_len = int(strings[1])

    array = [] * arr_len

    iterator = 0
    for i in range(arr_len):
        buf = []
        for j in range(sub_arr_len):
            buf.append(strings[iterator])
            iterator += 1
        array.append(buf)

    #for i in range(len(array)):
    #    print(array[i][17])
    return array


if __name__ == '__main__':
    loadArray('examples')