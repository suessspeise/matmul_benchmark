import time 

def sleep(seconds):
    #print('start')
    t0 = time.time()
    time.sleep(seconds)
    t1 = time.time()
    #print('end')
    print("Elapsed: {} ms".format((t1 - t0) * 1000))

if __name__ == '__main__':
    sleep(5)
