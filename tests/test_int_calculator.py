from src.int_calculator import IntCalculator


def test_add():
    assert IntCalculator(1, 2).add() == 3


def test_subtract():
    return IntCalculator(1, 2).subtract() == -1


def test_multiply():
    return IntCalculator(2, 3).multiply() == 6


def test_devide():
    return IntCalculator(6, 2).devide() == 3
