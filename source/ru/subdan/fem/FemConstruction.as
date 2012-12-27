// =============================================================================
//
//	Библиотека классов для расчета плоской
//  стержневой конструкции методом конечных элементов.
//	Copyright (c) 2012 Субботин Даниил (subdan@me.com)
//
// =============================================================================
package ru.subdan.fem
{
	/**
	 * Класс описывает плоскую стержневую конструкцию.
	 */
	public class FemConstruction
	{
		// Массив стержней
		private var _rodesArr:Vector.<FemRod>;
		// Количество стержней
		private var _rodesNum:int;

		// Массив узлов
		private var _nodesArr:Vector.<FemNode>;
		// Количество узлов
		private var _nodesNum:int;

		/**
		 * @constructor
		 */
		public function FemConstruction()
		{
			init();
		}

		//----------------------------------------------------------------------
		//
		//  Private methods
		//
		//----------------------------------------------------------------------

		/**
		 * Инициализация конструкции.
		 */
		private function init():void
		{
			_rodesNum = 0;
			_rodesArr = new <FemRod>[];
			_nodesNum = 0;
			_nodesArr = new <FemNode>[];
		}

		//----------------------------------------------------------------------
		//
		//  Public methods
		//
		//----------------------------------------------------------------------

		/**
		 * Добавляет стержень в конструкцию.
		 * @param rod Стержень, который необходимо добавить в конструкцию.
		 * @return Возвращает добавленный стержень.
		 */
		public function addRod(rod:FemRod):FemRod
		{
			_rodesArr[_rodesNum] = rod;
			_rodesNum++;
			return rod;
		}

		/**
		 * Добавляет узел в конструкцию.
		 * @param node Узел, который добавить в систему.
		 * @return Возвращает добавленый узел.
		 */
		public function addNode(node:FemNode):FemNode
		{
			_nodesArr[_nodesNum] = node;
			_nodesNum++;
			return node;
		}

		/**
		 * Вычисляет внутренние усилия в каждом стержне.
		 * @return Массив усилий. В случае ошибки вернет пустой массив.
		 */
		public function calculateAll():Array
		{
			// 1. Формирование матрицы жесткости всей конструкции

			var R:Array = FemMath.getMatrix(_nodesNum * 3, _nodesNum * 3);
			for (var l:int = 0; l < _rodesNum; l++)
			{
				var rod:FemRod = _rodesArr[l];

				var n:int = rod.from.id - 1;
				var k:int = rod.to.id - 1;

				for (var i:int = 0; i < 3; i++)
				{
					for (var j:int = 0; j < 3; j++)
					{
						R[n * 3 + i][n * 3 + j] += rod.Rg[i][j];
						R[n * 3 + i][k * 3 + j] += rod.Rg[i][j + 3];
						R[k * 3 + i][n * 3 + j] += rod.Rg[i + 3][j];
						R[k * 3 + i][k * 3 + j] += rod.Rg[i + 3][j + 3];
					}
				}
			}

			// 2. Учет граничных условий

			for (l = 0; l < _nodesNum; l++)
			{
				var node:FemNode = _nodesArr[l];

				if (node.type == FemNode.TYPE_HARD)
				{
					FemMath.freeColRow(R, (node.id - 1) * 3);
					FemMath.freeColRow(R, (node.id - 1) * 3 + 1);
					FemMath.freeColRow(R, (node.id - 1) * 3 + 2);
				}
				else if (node.type == FemNode.TYPE_HING_FIXED)
				{
					FemMath.freeColRow(R, (node.id - 1) * 3);
					FemMath.freeColRow(R, (node.id - 1) * 3 + 1);
				}
				else if (node.type == FemNode.TYPE_HING_MOVED)
				{
					if (node.angle == 0 || node.angle == 180)
						FemMath.freeColRow(R, (node.id - 1) * 3 + 1);
					else if (node.angle == 90 || node.angle == 270)
						FemMath.freeColRow(R, (node.id - 1) * 3);
				}
			}

			// 3. Формирование вектора нагрузок (узловых сил)

			var size:int = _nodesNum * 3;
			var P:Array = new Array(size);
			for (i = 0; i < size; i++)
			{
				P[i] = [];
				if (FemMath.getPart(i) == 1)
					P[i][0] = (_nodesArr[Math.floor(i / 3)] as FemNode).FX;
				else if (FemMath.getPart(i) == 2)
					P[i][0] = (_nodesArr[Math.floor(i / 3)] as FemNode).FY;
				else if (FemMath.getPart(i) == 3)
					P[i][0] = (_nodesArr[Math.floor(i / 3)] as FemNode).FM;
			}

			// 4. Подготовка к решению системы методом гаусса

			var m:Array = FemMath.getMatrix(size, size + 1);
			for (i = 0; i < size; i++)
				for (j = 0; j < size + 1; j++)
					m[i][j] = j == size ? -P[i][0] : R[i][j];

			// 5. Решение систеы уравнений методом гаусса

			var Z:Array = FemMath.gauss(m);
			if (!Z.length) return [];

			// 6. Вычисление векторов узловых перемещений
			// конечных элементов в общей системе координат

			var ans:Array = new Array(_rodesNum);
			for (i = 0; i < _rodesNum; i++)
			{
				rod = _rodesArr[i];
				n = rod.from.id - 1;
				k = rod.to.id - 1;

				rod.zg = new Array(6);

				for (j = 0; j < 3; j++)
					rod.zg[j] = Z[n * 3 + j]; // Заполнение X, Y, M в начале

				for (j = 0; j < 3; j++)
					rod.zg[j + 3] = Z[k * 3 + j]; // Заполнение X, Y, M в конце

				// 7. Вычисление вектора узловых перемещений стержня в местной СК

				rod.calcLocalOffset();

				// 8. Вычисление вектора внутренних сил стержня в местной СК

				rod.calcLocalForce();
				ans[i] = rod.rl;
			}

			return ans;
		}

		/**
		 * Удаляет все стержни и узлы из конструкции.
		 */
		public function resetAll():void
		{
			for (var i:int = 0; i < _rodesNum; i++)
				_rodesArr[i].free();
			init();
		}
	}
}
