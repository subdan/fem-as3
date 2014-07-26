// =============================================================================
//
//  Библиотека классов для расчета плоской
//  стержневой конструкции методом конечных элементов.
//  Copyright (c) 2014 Субботин Даниил (mail@subdan.ru)
//
// =============================================================================
package ru.subdan.fem
{
	import flash.geom.Point;

	/**
	 * Класс FemMath предназначен для выполнения различных математических операций.
	 */
	public class FemMath
	{
		/**
		 * Умножает одну матрицу на другую.
		 * @param matr1 Матрицу, которую надо умножить.
		 * @param matr2 Матрица, на которую надо умножить.
		 * @return Возвращает произведение двух матриц.
		 */
		public static function multiplyMatrix(matr1:Array, matr2:Array):Array
		{
			// Определение размерности матриц
			var m1:int = matr1.length;
			var n1:int = matr1[0].length;

			var m2:int = matr2.length;
			var n2:int = matr2[0] is Array ? matr2[0].length : 1;

			// Проверка на согласованность матриц
			if (n1 != m2) return [];

			// Создаем матрицу как двумерный массив
			var _resMatr:Array = getMatrix(m1, n2);

			// Умножение матриц
			for (var i:int = 0; i < m1; i++)
			{
				for (var j:int = 0; j < n2; j++)
				{
					_resMatr[i][j] = 0;
					for (var k:int = 0; k < n1; k++)
					{
						if (n2 == 1)
							_resMatr[i][j] += matr1[i][k] * matr2[k];
						else
							_resMatr[i][j] += matr1[i][k] * matr2[k][j];
					}
				}
			}

			return _resMatr;
		}

		/**
		 * Транпонирует матрицу.
		 * @param arr Матрицу, которую необходимо транспонировать.
		 * @return Возвращает транспонированную матрицу.
		 */
		public static function transpose(arr:Array):Array
		{
			// Определение размерности матрицы
			var m:int = arr.length;
			var n:int = arr[0].length;

			// Создаем матрицу как двумерный массив
			var _m:Array = getMatrix(m, n);

			// Транспонирование
			for (var i:int = 0; i < m; i++)
				for (var k:int = 0; k < n; k++)
					_m[k][i] = arr[i][k];

			return _m;
		}

		/**
		 * Рассчитывает расстояние между двумя точками.
		 * @param p1 Координаты первой точки.
		 * @param p2 Координаты второй точки.
		 * @return Возвращает расстояние между точками.
		 */
		public static function distance(p1:Point, p2:Point):Number
		{
			var dx:Number = p2.x - p1.x;
			var dy:Number = p2.y - p1.y;
			return Math.sqrt(dx * dx + dy * dy);
		}

		/**
		 * Создает массив заданной размерности.
		 * @param m Количество строк.
		 * @param n Количество столбцов.
		 * @return Возвращает массив заданной размерности заполненный нулями.
		 */
		public static function getMatrix(m:int, n:int):Array
		{
			var arr:Array = new Array(m);
			for (var i:int = 0; i < m; i++)
			{
				arr[i] = new Array(n);
				for (var j:int = 0; j < n; j++)
				{
					arr[i][j] = 0;
				}
			}
			return arr;
		}

		/**
		 * Зеркально отражает элементы матрицы, находящиеся выше главной диагонали.
		 */
		public static function mirror(matrix:Array):void
		{
			var m:int = matrix.length;

			for (var i:int = 0; i < m - 1; i++)
			{
				for (var j:int = 0; j < m - 1; j++)
				{
					matrix[j + 1][i] = matrix[i][j + 1];
				}
			}
		}

		/**
		 * Выводит в окно output матрицу по строкам.
		 * @param matrix Матрица, которую необходимо вывести в окно output.
		 */
		public static function traceMatrix(matrix:Array):void
		{
			var str:String = "";
			for (var i:int = 0; i < matrix.length; i++)
			{
				for (var j:int = 0; j < matrix[i].length; j++)
				{
					str += (matrix[i][j] + "\t\t");
				}
				trace(str);
				str = "";
			}
		}

		/**
		 * Решает матрицу методом Гаусса.
		 * @param matr Исходная матрица
		 * @return Ответ в виде вектора неизвестных.
		 */
		public static function gauss(matr:Array):Array
		{
			return simpleIter(matr);
			var m:int = matr.length;
			if (!m) return [];
			var n:int = matr[0].length;

			if (n != m + 1 || m == 0 || n == 0) return [];

			var x:Array = new Array(m);

			// Прямой ход
			for (var k:int = 0; k < m - 1; k++)
			{
				mainElem(matr, k);

				var r:Number = matr[k][k];

				if (r == 0) return [];

				for (var j:int = 0; j < n; j++)
					matr[k][j] /= r;

				for (var i:int = k + 1; i < m; i++)
				{
					r = matr[i][k];
					for (j = k; j < n; j++)
						matr[i][j] -= matr[k][j] * r;
				}
			}

			// Обратный ход.
			if (matr[m - 1][n - 2] == 0) return [];
			x[m - 1] = -matr[m - 1][n - 1] / matr[m - 1][n - 2];

			for (k = n - 3; k >= 0; k--)
			{
				x[k] = -matr[k][n - 1];
				for (j = k + 1; j < n - 1; j++)
					x[k] -= matr[k][j] * x[j];
			}

			return x;
		}

		/**
		 * Выбирает главный элемент (наибольший по модулю) в столбце.
		 * a - Двумерный массив.
		 * k - Номер элемента главной диагонали.
		 */
		private static function mainElem(a:Array, k:int):void
		{
			// Инициируем переменную "r" как модуль первого элемента главной диагонали
			var r:Number = Math.abs(a[k][k]);
			var m:int = k;
			var z:Array;

			// Находим наибольший по модулю элемент и записываем в переменную "r".
			for (var i:int = k + 1; i < a.length; i++)
			{
				if (Math.abs(a[i][k]) > r)
				{
					r = Math.abs(a[i][k]);
					m = i;
				}
			}

			if (m != k)
			{
				z = a[k];
				a[k] = a[m];
				a[m] = z;
			}
		}

		public static function simpleIter(matrix:Array):Array
		{
			var size:int = matrix.length;
			var eps:Number = 0.0001;

			var previousVariableValues:Array = [];
			for (var i:int = 0; i < size; i++)
			{
				previousVariableValues[i] = 0.0;
			}

			// Будем выполнять итерационный процесс до тех пор,
			// пока не будет достигнута необходимая точность
			while (true)
			{
				// Введем вектор значений неизвестных на текущем шаге
				var currentVariableValues:Array = [];

				// Посчитаем значения неизвестных на текущей итерации
				// в соответствии с теоретическими формулами
				for (i = 0; i < size; i++)
				{
					// Инициализируем i-ую неизвестную значением
					// свободного члена i-ой строки матрицы
					currentVariableValues[i] = matrix[i][size];

					// Вычитаем сумму по всем отличным от i-ой неизвестным
					for (var j:int = 0; j < size; j++)
					{
						// При j < i можем использовать уже посчитанные
						// на этой итерации значения неизвестных
						if (j < i)
						{
							currentVariableValues[i] -= matrix[i][j] * currentVariableValues[j];
						}

						// При j > i используем значения с прошлой итерации
						if (j > i)
						{
							currentVariableValues[i] -= matrix[i][j] * previousVariableValues[j];
						}
					}

					// Делим на коэффициент при i-ой неизвестной
					currentVariableValues[i] /= matrix[i][i];
				}

				// Посчитаем текущую погрешность относительно предыдущей итерации
				var error:Number = 0.0;

				for (i = 0; i < size; i++)
				{
					error += Math.abs(currentVariableValues[i] - previousVariableValues[i]);
				}

				// Если необходимая точность достигнута, то завершаем процесс
				if (error < eps)
				{
					break;
				}

				// Переходим к следующей итерации, так
				// что текущие значения неизвестных
				// становятся значениями на предыдущей итерации
				previousVariableValues = currentVariableValues;
			}

			return previousVariableValues;
		}

		/**
		 * @param num Целое число от 0.
		 * @return Возвращает позицию числа из группы трех чисел.
		 */
		public static function getPart(num:int):int
		{
			return num % 3 + 1;
		}

		/**
		 * Зануляет указанную строку и столбец. На диагонали ставит единицу.
		 * @param a Матрица жесткости всей конструкции.
		 * @param n Какой узел занулить.
		 */
		public static function freeColRow(a:Array, n:int):void
		{
			for (var j:int = 0; j < a.length; j++)
			{
				if (n == j)
					a[n][j] = 0.001;
				else
					a[n][j] = 0;
			}

			for (j = 0; j < a.length; j++)
			{
				if (n == j) a[j][n] = 0.001;
				else a[j][n] = 0;
			}
		}

		/**
		 * Округляет число до заданной точности.
		 * @param num Число.
		 * @param precision Точность.
		 * @return Возвращает округленнное число.
		 */
		public static function roundDecimal(num:Number, precision:int):Number
		{
			var decimal:Number = Math.pow(10, precision);
			return Math.round(decimal * num) / decimal;
		}

		/**
		 * Представляет число в текстовом виде
		 * @param number Число.
		 * @param maxDecimals Максимальное число знаков после запятой.
		 * @param forceDecimals Принудительно добавлять нули.
		 */
		public static function numberFormat(number:*, maxDecimals:int = 2, forceDecimals:Boolean = false):String
		{
			var i:int = 0;
			var inc:Number = Math.pow(10, maxDecimals);
			var str:String = String(Math.round(inc * Number(number)) / inc);
			var hasSep:Boolean = str.indexOf(".") == -1, sep:int = hasSep ? str.length : str.indexOf(".");
			var ret:String = (hasSep && !forceDecimals ? "" : ".") + str.substr(sep + 1);
			if (forceDecimals)
			{
				for (var j:int = 0; j <= maxDecimals - (str.length - (hasSep ? sep - 1 : sep)); j++) ret += "0";
			}
			return str.substr(0, sep - i) + ret;
		}
	}
}
