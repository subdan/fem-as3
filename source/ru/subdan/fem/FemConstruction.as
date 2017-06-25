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
	import flash.utils.Dictionary;
	
	/**
	 * Класс FemConstruction описывает плоскую стержневую конструкцию.
	 */
	public class FemConstruction
	{
		// Степень интегрирования равномерно распределенной нагрузки.
		public static const DISTR_STEP:int = 100;
		
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
		
		// Массив удаленных распределенных стержней
		private var _distrRods:Array;
		
		/**
		 * @constructor
		 */
		public function FemConstruction()
		{
			init();
		}
		
		//----------------------------------------------------------------------
		//
		//  PRIVATE METHODS
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
			
			_distrRods = [];
		}
		
		//----------------------------------------------------------------------
		//
		//  PUBLIC METHODS
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
		 * Вычисляет внутренние усилия и перемещения в каждом стержне.
		 * @return Успешность выполнения расчета.
		 */
		public function calculateAll():Boolean
		{
			// Прежде, чем производить расчет, заменим все стержни, имеющие
			// равномерно распределенную нагрузку на множество стержней и узлов
			// к узлам приложим эквивалентную узловую нагрузку.
			
			var hasDistrLoad:Boolean = false;
			var rodToSplit:Vector.<FemRod> = new <FemRod>[];
			for each(var rod1:FemRod in _rodsArr)
			{
				if (rod1.distributedLoad)
				{
					rodToSplit.push(rod1);
				}
			}
			for each(var rod2:FemRod in rodToSplit)
			{
				splitRod(rod2);
				_rodsArr.splice(_rodsArr.indexOf(rod2), 1);
				_rodsNum--;
				_distrRods.push(rod2);
				rod2 = null;
			}
			
			//----------------------------------
			
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
				var fnode:FemNode = _nodesArr[l];
				
				if (fnode.type == FemNode.TYPE_HARD)
				{
					FemMath.freeColRow(R, (fnode.id - 1) * 3);
					FemMath.freeColRow(R, (fnode.id - 1) * 3 + 1);
					FemMath.freeColRow(R, (fnode.id - 1) * 3 + 2);
				}
				else if (fnode.type == FemNode.TYPE_HING_FIXED)
				{
					FemMath.freeColRow(R, (fnode.id - 1) * 3);
					FemMath.freeColRow(R, (fnode.id - 1) * 3 + 1);
				}
				else if (fnode.type == FemNode.TYPE_HING_MOVED)
				{
					if (fnode.angle == 0 || fnode.angle == 180)
						FemMath.freeColRow(R, (fnode.id - 1) * 3 + 1);
					else if (fnode.angle == 90 || fnode.angle == 270)
						FemMath.freeColRow(R, (fnode.id - 1) * 3);
				}
			}
			
			// 3. Формирование вектора нагрузок (узловых сил)
			var size:int = _nodesNum * 3;
			var P:Array = new Array(size);
			for (i = 0; i < size; i++)
			{
				P[i] = [];
				
				var fsnode:FemNode = (_nodesArr[Math.floor(i / 3)] as FemNode);
				
				if (FemMath.getPart(i) == 1)
				{
					if (fsnode.type == FemNode.TYPE_NONE || (fsnode.type == FemNode.TYPE_HING_MOVED && (fsnode.angle == 0 || fsnode.angle == 180)))
					{
						P[i][0] = fsnode.loadX;
					}
					else
					{
						P[i][0] = 0;
					}
				}
				else if (FemMath.getPart(i) == 2)
				{
					if (fsnode.type == FemNode.TYPE_NONE || (fsnode.type == FemNode.TYPE_HING_MOVED && (fsnode.angle == 90 || fsnode.angle == 270)))
					{
						P[i][0] = fsnode.loadY;
					}
					else
					{
						P[i][0] = 0;
					}
				}
				else if (FemMath.getPart(i) == 3)
				{
					if (fsnode.type != FemNode.TYPE_HARD)
						P[i][0] = fsnode.loadM;
					else
						P[i][0] = 0;
				}
			}
			
			// 4. Подготовка к решению системы методом гаусса
			var m:Array = FemMath.getMatrix(size, size + 1);
			for (i = 0; i < size; i++)
				for (j = 0; j < size + 1; j++)
					m[i][j] = j == size ? -P[i][0] : R[i][j];

			// 5. Решение систеы уравнений методом гаусса
			var Z:Array = FemMath.gauss(m);
			
			trace(Z);
			
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
				rod.from.offsetX = Number(FemMath.numberFormat(rod.zg[0], 4, true));
				rod.from.offsetY = Number(FemMath.numberFormat(rod.zg[1], 4, true));
				rod.from.offsetM = Number(FemMath.numberFormat(rod.zg[2], 8, true));
				
				// Заполнение X, Y, M в конце
				rod.to.offsetX = Number(FemMath.numberFormat(rod.zg[3], 4, true));
				rod.to.offsetY = Number(FemMath.numberFormat(rod.zg[4], 4, true));
				rod.to.offsetM = Number(FemMath.numberFormat(rod.zg[5], 8, true));
				
				// 8. Вычисление вектора внутренних сил стержня в местной СК
				rod.calcLocalForce();
				rod.factorNFrom = Number(FemMath.numberFormat(rod.rl[0], 4, true));
				rod.factorNTo = Number(FemMath.numberFormat(rod.rl[3], 4, true));
				rod.factorQFrom = Number(FemMath.numberFormat(rod.rl[1], 4, true));
				rod.factorQTo = Number(FemMath.numberFormat(rod.rl[4], 4, true));
				rod.factorMFrom = Number(FemMath.numberFormat(rod.rl[2], 4, true));
				rod.factorMTo = Number(FemMath.numberFormat(rod.rl[5], 4, true));
			}
			
			// Последний шаг – собрать разбитые стержни.
			
			// Для начала удалим все не нужные узлы
			var nodesToDelete:Array = [];
			for each (var node:FemNode in _nodesArr)
				if (node.distributed)
					nodesToDelete.push(node);
			
			while (nodesToDelete.length)
			{
				_nodesArr.splice(_nodesArr.indexOf(nodesToDelete[0]), 1);
				_nodesNum--;
				nodesToDelete.splice(0, 1);
			}
			
			// Далее восстановим удаленные стержни
			for (i = 0; i < _distrRods.length; i++)
				addRod(_distrRods[i]);
			
			// Далее удалим распределенные кусочки стержней
			var rodsToDelete:Array = [];
			for (i = 0; i < _rodsArr.length; i++)
			{
				var frod:FemRod = _rodsArr[i];
				if (frod.distributed)
				{
					rodsToDelete.push(frod);
				}
				else if (frod.distributedLoad)
				{
					frod.factorMFrom = frod.distributedRods[0].factorMFrom;
					frod.factorQFrom = frod.distributedRods[0].factorQFrom;
					frod.factorNFrom = frod.distributedRods[0].factorNFrom;
					
					for (j = 0; j < frod.distributedRods.length; j++)
					{
						frod.factorsM.push(frod.distributedRods[j].factorMFrom);
						frod.factorsQ.push(frod.distributedRods[j].factorQFrom);
						frod.factorsN.push(frod.distributedRods[j].factorNFrom);
					}
					
					frod.factorMTo = frod.distributedRods[frod.distributedRods.length - 1].factorMTo;
					frod.factorQTo = frod.distributedRods[frod.distributedRods.length - 1].factorQTo;
					frod.factorNTo = frod.distributedRods[frod.distributedRods.length - 1].factorNTo;
				}
			}
			while (rodsToDelete.length)
			{
				_rodsArr.splice(_rodsArr.indexOf(rodsToDelete[0]), 1);
				_rodsNum--;
				rodsToDelete.splice(0, 1);
			}
			
			return true;
		}
		
		private function splitRod(rod:FemRod):void
		{
			var len:Number = FemMath.distance(rod.to.pos, rod.from.pos);
			var partLen:Number = len / (DISTR_STEP + 1);
			var ang:Number = Math.atan2(rod.to.pos.y - rod.from.pos.y, rod.to.pos.x - rod.from.pos.x)
			
			var prevX:Number = rod.from.pos.x;
			var prevY:Number = rod.from.pos.y;
			var nextX:Number;
			var nextY:Number;
			
			var prevNode:FemNode;
			var femRod:FemRod;
			
			var Q:Number = rod.distributedLoad * len;
			var partQ:Number;
			
			partQ = Q / (DISTR_STEP + 1);
			rod.from.loadX += -partQ / 2 * Math.sin(ang);
			rod.from.loadY += partQ / 2 * Math.cos(ang);
			rod.to.loadX += -partQ / 2 * Math.sin(ang);
			rod.to.loadY += partQ / 2 * Math.cos(ang);
			
			//rod.from.loadM += Q * len * len / 12 / DISTR_STEP
			//rod.to.loadM += Q * len * len / 12 / DISTR_STEP;
			
			// http://window.edu.ru/resource/481/74481/files/ulstu2011-36.pdf
			var arr:Array = [];
			for (var i:int = 0; i < DISTR_STEP; i++)
			{
				var femNode:FemNode = new FemNode(_nodesNum + 1, new Point(0, 0), FemNode.TYPE_NONE, 0);
				femNode.distributed = true;
				femNode.distributedRod = rod;
				nextX = prevX + Math.cos(ang) * partLen;
				nextY = prevY + Math.sin(ang) * partLen;
				femNode.pos.x = nextX;
				femNode.pos.y = nextY;
				femNode.loadX = -partQ * Math.sin(ang);
				femNode.loadY = partQ * Math.cos(ang);
				addNode(femNode);
				
				if (i == 0)
				{
					femRod = addRod(new FemRod(_rodsNum + 1, rod.material, rod.from, femNode));
					femRod.distributed = true;
					femRod.distributedRod = rod;
				}
				else if (prevNode)
				{
					femRod = addRod(new FemRod(_rodsNum + 1, rod.material, prevNode, femNode));
					femRod.distributed = true;
					femRod.distributedRod = rod;
				}
				
				arr.push(femRod);
				
				prevNode = femNode;
				prevX = femNode.pos.x;
				prevY = femNode.pos.y;
			}
			
			femRod = addRod(new FemRod(_rodsNum + 1, rod.material, prevNode, rod.to));
			femRod.distributed = true;
			femRod.distributedRod = rod;
			arr.push(femRod);
			
			rod.distributedRods = arr;
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
		//  GET/SET METHODS
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
