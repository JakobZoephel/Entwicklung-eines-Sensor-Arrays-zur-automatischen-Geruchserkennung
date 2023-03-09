# ähnlich wie die Processing Funktion, nur in Python
def loadArray(fileName):

    with open(fileName, "rb") as f:
        bytes = list(f.read())

    HEADER_VARIABLES = bytes[0]
    GLOBAL_PREFIX = bytes[1]
    GLOBAL_SIGNED = bytes[2]
    DECIMAL_SIZE = bytes[3]
    VALUE_SIZE = bytes[4]
    ARRAY_LENGTH = bytes[5]
    dataBits = 8 * len(bytes) - 8 * (HEADER_VARIABLES + 1)
    for i in range(8):
        if int(dataBits / (GLOBAL_PREFIX + GLOBAL_SIGNED + DECIMAL_SIZE + VALUE_SIZE)) == int((int(dataBits / (GLOBAL_PREFIX + GLOBAL_SIGNED + DECIMAL_SIZE + VALUE_SIZE)))):
            break
        dataBits -= 1

    VALUES = int(dataBits / (GLOBAL_PREFIX + GLOBAL_SIGNED + DECIMAL_SIZE + VALUE_SIZE))
    # int values = EXAMPLE_SIZE*arrayLength;
    BLOCK_SIZE = GLOBAL_PREFIX + GLOBAL_SIGNED + DECIMAL_SIZE + VALUE_SIZE
    OFFSET = VALUES * BLOCK_SIZE % 8
    bits = [None] * (VALUES * GLOBAL_PREFIX + VALUES * GLOBAL_SIGNED + VALUES * DECIMAL_SIZE + VALUES * VALUE_SIZE + OFFSET)
    currByte = None
    get_bin = lambda x, n: format(x, 'b').zfill(n)

    for i in range(0, len(bits), 8):
        currByte = get_bin(bytes[HEADER_VARIABLES + 1 + int(i / 8)], 8)
        for j in range(8):
            bits[i + j] = currByte[j]

    array = [[0.0] * (int(VALUES / ARRAY_LENGTH)) for _ in range(ARRAY_LENGTH)]

    for i in range(0, len(bits) - OFFSET, BLOCK_SIZE):
        block = ""
        for j in range(BLOCK_SIZE):
            block += str((bits[i + j]))
        if len(block) != BLOCK_SIZE:
            print("block.length() != blockSize, load")
        prefix = 0
        signed = 0
        deciamlIndex = 0
        value = 0.0
        if GLOBAL_PREFIX == 1:
            prefix = int(str(block[0]))
        if GLOBAL_SIGNED == 1:
            signed = int(str(block[1]))
        if DECIMAL_SIZE != 0:
            decimalBlock = ""
            j = 0
            for j in range(DECIMAL_SIZE):
                decimalBlock += block[GLOBAL_PREFIX + GLOBAL_SIGNED + j]
            deciamlIndex = int(decimalBlock, 2)
        valueBlock = ""
        for j in range(VALUE_SIZE):
            valueBlock += block[GLOBAL_PREFIX + GLOBAL_SIGNED + DECIMAL_SIZE + j]
        strValue = str(int(valueBlock, 2))
        if prefix == 1:
            strValue = str('0') + strValue
        value = addDecimalPoint(strValue, deciamlIndex)
        value *= -1 if signed == 1 else 1
        array[int((int(i / BLOCK_SIZE)) / (int(VALUES / ARRAY_LENGTH)))][(int(i / BLOCK_SIZE)) % (int(VALUES / ARRAY_LENGTH))] = value
    return array

def eraseDecimalPoint(f):
    s = eraseZeroes(str(f))
    if int(f) == f:
        return s
    return s.replace(".","")

def addDecimalPoint(s,  index):
    if index == 0:
        return float(s)
    s = s[0:index] + str('.') + s[index:len(s)]
    return float(s)

def getDeciamlIndex(d):
    text = "".join(abs(d))
    text = eraseZeroes(text)
    if len(text.split('.')) == 1:
        return 0
    number = 0
    if match(text, 'E') != None:
        number = len(text.replace(".","").split("E")[0])
    else:
        number = len(text.split('.')[0])
    return number

def match(text,  search):
    for i in range(len(text)):
        if text[i] == search:
            return search
    return None

def eraseZeroes(text):
    end = 0
    for i in range(len(text) - 1, 0, -1):
        if text[i] != '0':
            end = i
            break
    if end == len(text) - 2:
        return text[0:end]
    else:
        return text[0:end + 1]

def Values2Base(value,  BASE,  MAX_CHARS):
    # nur bis base 36 (Hexatrigesimal)
    if BASE > 36:
        return ""
    buffer = ""
    done = True
    if MAX_CHARS == -1:
        while True:
            if value >= BASE:
                buffer = str(getNumeralSystemChar(value % BASE)) + buffer
                value /= BASE
            elif done:
                buffer = str(getNumeralSystemChar(value)) + buffer
                done = False
            else:
                break
    else:
        for i in range(MAX_CHARS):
            if (value >= BASE):
                buffer = str(getNumeralSystemChar(value % BASE)) + buffer
                value /= BASE
            elif done:
                buffer = str(getNumeralSystemChar(value)) + buffer
                done = False
            else:
                buffer = str('0') + buffer
    return buffer

def getNumeralSystemChar(index):
    if index < 0 or index >= 36:
        return chr(-1)
    if index < 10:
        return chr(48 + index)
    else:
        return chr(55 + index)


if __name__ == '__main__':
   arr =  loadArray('examples')
   print(arr)