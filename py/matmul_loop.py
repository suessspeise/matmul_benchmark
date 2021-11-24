import numpy as np

# naive implementation, most possibly the worst performance.
def matmul_loop(a,b):
    c = np.copy(a)
    for j in range(c.shape[0]):
        for i in range(c.shape[1]):
            prod = 0.0 
            for k in range(c.shape[0]):
                prod += a[i][k] * b[k][j]
            c[i][j] = prod    
    return c

if __name__ == "__main__":
    print('module matmul_loop')
    print()
    print('matmul_loop( np.random.random_sample((3, 3)), np.random.random_sample((3, 3)))')
    print( matmul_loop( np.random.random_sample((3, 3)), np.random.random_sample((3, 3))) ) 
            
