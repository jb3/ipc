for i in range(1, 100_000_000):
    divisors = 0
    for num in range(2, i):
        if i % num == 0:
            divisors += 1
    if divisors == 1:
        print(i)
