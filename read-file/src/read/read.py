from os.path import join as _j 
def read_file(filename: str):
    with open(_j("data", filename), 'r') as f:
        print(f.read())