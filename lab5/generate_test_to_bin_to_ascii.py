def good_bin(number):
    b = bin(number)[2::]
    b = "0" * (8 - len(b)) + b
    return b

def biin(num):
    st = [0, 0, 0]
    st[0] = 0x30 + num % 10
    st[1] = 0x30 + (num % 100) //10
    st[2] = 0x30 + (num % 1000) //100
    
    ans = ""
    for i in range(3):
        st[i] = good_bin(st[i])
    return ''.join(st)

def all_vectors():
    f = open('C:/Gowin/FPGAProj/lab5/ASCIItest.tv', 'w+')
    for i in range(256):
        u, v = good_bin(13), good_bin(10)
        f.write(good_bin(i) + biin(i) + u + v)
        f.write('\n')
    f.close()
        
            
        
            

if __name__ == "__main__":
    all_vectors()
    
