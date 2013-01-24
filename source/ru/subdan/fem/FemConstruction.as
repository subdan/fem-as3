// =============================================================================
//
//  Библиотека классов для расчета плоской
//  стержневой конструкции методом конечных элементов.
//  Copyright (c) 2012 Субботин Даниил (subdan@me.com)
//
// =============================================================================
package ru.subdan.fem
{
	import flash.utils.Dictionary;

	/**
	 * Класс описывает плоскую стержневую конструкцию.
	 */
	public class FemConstruction
	{
		// Массив стержней
		private var _rodsArr:Vector.<FemRod>;
		// Количество стержней
		private var _rodsNum:int;
		// Словарь стержней
		private var _rodsByID:Dictionary;

		// Массив узлов
		private var _nodesArr:Vector.<FemNode>;
		// Количество узлов
		private var _nodesNum:int;
		// Словарь узлов
		private var _nodesByID:Dictionary;

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
			_rodsNum = 0;
			_rodsArr = new <FemRod>[];
			_rodsByID = new Dictionary();

			_nodesNum = 0;
			_nodesArr = new <FemNode>[];
			_nodesByID = new Dictionary();
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
			_rodsArr[_rodsNum] = rod;
			_rodsByID[rod.id] = rod;
			_rodsNum++;
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
			_nodesByID[node.id] = node;
			_nodesNum++;
			return node;
		}

		/**
		 * Возвращает узел по его идентификатору.
		 * @param id Идентификатор узла.
		 * @return Возвращает узел.
		 */
		public function getNode(id:int):FemNode
		{
			return _nodesByID[id];
		}

		/**
		 * Возвращает стержень по его идентификатору.
		 * @param id Идентификатор стержня.
		 * @return Возвращает стержень.
		 */
		public function getRod(id:int):FemRod
		{
			return _rodsByID[id];
		}

		/**
		 * Вычисляет внутренние усилия в каждом стержне.
		 * @return Успешность выполнения расчета.
		 */
		public function calculateAll():Boolean
		{
			// 0. Расчет глобальной матрицы R всех стержней

			for (var i:int = 0; i < _rodsNum; i++)
			{
				_rodsArr[i].calcLocalAndGlobalR();
			}

			// 1. Формирование матрицы жесткости всей конструкции

			var R:Array = FemMath.getMatrix(_nodesNum * 3, _nodesNum * 3);
			for (var l:int = 0; l < _rodsNum; l++)
			{
				var rod:FemRod = _rodsArr[l];

				var n:int = rod.from.id - 1;
				var k:int = rod.to.id - 1;

				for (i = 0; i < 3; i++)
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
					P[i][0] = (_nodesArr[Math.floor(i / 3)] as FemNode).loadX;
				else if (FemMath.getPart(i) == 2)
					P[i][0] = (_nodesArr[Math.floor(i / 3)] as FemNode).loadY;
				else if (FemMath.getPart(i) == 3)
					P[i][0] = (_nodesArr[Math.floor(i / 3)] as FemNode).loadM;
			}

			// 4. Подготовка к решению системы методом гаусса

			var m:Array = FemMath.getMatrix(size, size + 1);
			for (i = 0; i < size; i++)
				for (j = 0; j < size + 1; j++)
					m[i][j] = j == size ? -P[i][0] : R[i][j];

			// 5. Решение систеы уравнений методом гаусса

			var Z:Array = FemMath.gauss(m);
			if (!Z.length) return false;

			// 6. Вычисление векторов узловых перемещений
			// конечных элементов в общей системе координат

			for (i = 0; i < _rodsNum; i++)
			{
				rod = _rodsArr[i];
				n = rod.from.id - 1;
				k = rod.to.id - 1;

				rod.zg = new Array(6);

				for (j = 0; j < 3; j++)
				{
					// Заполнение X, Y, M в начале
					rod.zg[j] = Z[n * 3 + j];
				}

				for (j = 0; j < 3; j++)
				{
					// Заполнение X, Y, M в конце
					rod.zg[j + 3] = Z[k * 3 + j];
				}

				// 7. Вычисление вектора узловых перемещений стержня в местной СК

				rod.calcLocalOffset();

				// Заполнение X, Y, M в начале
				rod.from.offsetX = Number(FemMath.numberFormat(rod.zl[0], 4, true));
				rod.from.offsetY = Number(FemMath.numberFormat(rod.zl[1], 4, true));
				rod.from.offsetM = Number(FemMath.numberFormat(rod.zl[2], 4, true));

				// Заполнение X, Y, M в конце
				rod.to.offsetX = Number(FemMath.numberFormat(rod.zl[3], 4, true));
				rod.to.offsetY = Number(FemMath.numberFormat(rod.zl[4], 4, true));
				rod.to.offsetM = Number(FemMath.numberFormat(rod.zl[5], 4, true));

				// 8. Вычисление вектора внутренних сил стержня в местной СК

				rod.calcLocalForce();

				rod.factorNFrom = Number(FemMath.numberFormat(rod.rl[0], 4, true));
				rod.factorNTo = Number(FemMath.numberFormat(rod.rl[3], 4, true));
				rod.factorQFrom = Number(FemMath.numberFormat(rod.rl[1], 4, true));
				rod.factorQTo = Number(FemMath.numberFormat(rod.rl[4], 4, true));
				rod.factorMFrom = Number(FemMath.numberFormat(rod.rl[2], 4, true));
				rod.factorMTo = Number(FemMath.numberFormat(rod.rl[5], 4, true));
			}

			return true;
		}

		/**
		 * Удаляет все стержни и узлы из конструкции.
		 */
		public function resetAll():void
		{
			for (var i:int = 0; i < _rodsNum; i++)
				_rodsArr[i].free();
			init();
		}

		//----------------------------------------------------------------------
		//
		//  Get/Set methods
		//
		//----------------------------------------------------------------------

		public function get rodsArr():Vector.<FemRod>
		{
			return _rodsArr;
		}

		public function get nodesArr():Vector.<FemNode>
		{
			return _nodesArr;
		}
	}
}
