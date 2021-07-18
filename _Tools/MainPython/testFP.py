def identity_print(x):      # "identity with side-effect"
    print(x)
    return x


def echo_FP(): return identity_print(input("FP -- ")) == 'quit' or echo_FP()


echo_FP()
