class IntCalculator:
    def __init__(self, a: int, b: int):
        self.a = a
        self.b = b

    def add(self) -> int:
        return self.a + self.b

    def subtract(self) -> int:
        return self.a - self.b

    def multiply(self) -> int:
        return self.a * self.b

    def devide(self) -> int:
        return self.a / self.b
