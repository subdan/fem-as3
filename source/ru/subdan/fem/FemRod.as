// =============================================================================
//
//  Библиотека классов для расчета плоской
//  стержневой конструкции методом конечных элементов.
//  Copyright (c) 2014 Субботин Даниил (mail@subdan.ru)
//
// =============================================================================
package ru.subdan.fem
{
	/**
	 * Класс FemRod описывает конечный элемент (стержень).
	 */
	public class FemRod
	{
		//----------------------------------
		//  PUBLIC VARIABLES
		//----------------------------------

		/**
		 * Идентификатор стержня.
		 */
		public var id:int;

		/**
		 * Материал стержня.
		 */
		public var material:FemMaterial;

		/**
		 * Начальный узел стержня.
		 */
		public var from:FemNode;

		/**
		 * Конечный узел стержня.
		 */
		public var to:FemNode;

		/**
		 * Есть ли в начале стержня шарнир.
		 */
		public var hasStartJoint:Boolean;

		/**
		 * Есть ли в конце стержня шарнир.
		 */
		public var hasEndJoint:Boolean;

		/**
		 * Является ли этот стержень частью большого.
		 */
		public var distributed:Boolean;

		/**
		 * Если стержень является частью большого, то какого.
		 */
		public var distributedRod:FemRod;
		
		// Массив дополнительных КЭ
		public var distributedRods:Array;
		
		//----------------------------------
		//  Нагрузка
		//----------------------------------
		
		/**
		 * Равномерно распределенная нагрузка на стержень.
		 */
		public var distributedLoad:Number;

		//----------------------------------
		//  Результаты расчета
		//----------------------------------
		
		/**
		 * Значение продольной силы в начале стержня после выполнения расчета.
		 */
		public var factorNFrom:Number;

		/**
		 * Значение продольной силы в конце стержня после выполнения расчета.
		 */
		public var factorNTo:Number;

		/**
		 * Значение поперечной силы в начале стержня после выполнения расчета.
		 */
		public var factorQFrom:Number;

		/**
		 * Значение поперечной силы в конце стержня после выполнения расчета.
		 */
		public var factorQTo:Number;

		/**
		 * Значение момента в начале стержня после выполнения расчета.
		 */
		public var factorMFrom:Number;

		/**
		 * Значение момента в конце стержня после выполнения расчета.
		 */
		public var factorMTo:Number;
		
		// Если стержень имеен равномерно распределенную нагрузку то смотри ниже.

		public var factorsM:Array = [];
		public var factorsN:Array = [];
		public var factorsQ:Array = [];

		//----------------------------------
		//  PRIVATE VARIABLES
		//----------------------------------

		// Матрица жесткости стержня в местной системе координат
		private var _Rl:Array;
		// Матрица жесткости стержня в общей системе координат
		private var _Rg:Array;

		// Матрица преобразования
		private var _V:Array;

		// Вектор узловых перемещений в местной системе координат
		private var _zl:Array;
		// Вектор узловых перемещений в общей системе координат
		private var _zg:Array;

		// Вектор концевых усилий в местной системе координат
		private var _rl:Array;

		/**
		 * @constructor
		 * @param id Идентификатор стержня.
		 * @param material Материал стержня.
		 * @param from Узел начала стержня.
		 * @param to Узел конца стержня.
		 */
		public function FemRod(id:int, material:FemMaterial, from:FemNode, to:FemNode)
		{
			this.id = id;
			this.material = material;
			this.from = from;
			this.to = to;
		}

		//----------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//----------------------------------------------------------------------

		/**
		 * Вычисляет матрицу жесткости стержня в местной и общей СК.
		 */
		public function calcLocalAndGlobalR():void
		{
			// Расчет длины конечного элемента
			var len:Number = FemMath.distance(from.pos, to.pos);

			// Расчет косинуса и синуса угла наклона
			var sinA:Number = (to.pos.y - from.pos.y) / len;
			var cosA:Number = (to.pos.x - from.pos.x) / len;

			// Создание матрицы 6 на 6
			_Rl = FemMath.getMatrix(6, 6);

			// Заполнение половины матрицы
			if (!hasStartJoint && !hasEndJoint)
			{
				_Rl[0][0] = material.e * material.f / len;
				_Rl[0][3] = -_Rl[0][0];
				_Rl[1][1] = 12 * material.e * material.i / Math.pow(len, 3);
				_Rl[1][2] = 6 * material.e * material.i / Math.pow(len, 2);
				_Rl[1][4] = -_Rl[1][1];
				_Rl[1][5] = _Rl[1][2];
				_Rl[2][2] = 4 * material.e * material.i / len;
				_Rl[2][4] = -_Rl[1][5];
				_Rl[2][5] = _Rl[2][2] / 2;
				_Rl[3][3] = _Rl[0][0];
				_Rl[4][4] = _Rl[1][1];
				_Rl[4][5] = _Rl[2][4];
				_Rl[5][5] = _Rl[2][2];
			}
			else if (hasStartJoint)
			{
				_Rl[0][0] = _Rl[3][3] = material.e * material.f / len;
				_Rl[0][3] = _Rl[3][0] = -material.e * material.f / len;
				_Rl[1][1] = _Rl[4][4] = 3.0 * material.e * material.i / (len * len * len);
				_Rl[1][4] = _Rl[4][1] = -3.0 * material.e * material.i / (len * len * len);
				_Rl[2][2] = 0.001;
				_Rl[1][5] = _Rl[5][1] = 3.0 * material.e * material.i / (len * len);
				_Rl[4][5] = _Rl[5][4] = -3.0 * material.e * material.i / (len * len);
				_Rl[5][5] = 3.0 * material.e * material.i / len;
			}
			else if (hasEndJoint)
			{
				_Rl[0][0] = _Rl[3][3] = material.e * material.f / len;
				_Rl[0][3] = _Rl[3][0] = -material.e * material.f / len;
				_Rl[1][1] = _Rl[4][4] = 3.0 * material.e * material.i / (len * len * len);
				_Rl[1][4] = _Rl[4][1] = -3.0 * material.e * material.i / (len * len * len);
				_Rl[2][2] = 3.0 * material.e * material.i / len;
				_Rl[1][2] = _Rl[2][1] = 3.0 * material.e * material.i / (len * len);
				_Rl[4][2] = _Rl[2][4] = -3.0 * material.e * material.i / (len * len);
				_Rl[5][5] = 0.001;
			}
			else if (hasStartJoint && hasEndJoint)
			{
				_Rl[0][0] = _Rl[3][3] = material.e * material.f / len;
				_Rl[0][3] = _Rl[3][0] = -material.e * material.f / len;
				_Rl[1][1] = _Rl[4][4] = 0.001;
				_Rl[2][2] = 0.001;
				_Rl[5][5] = 0.001;
			}

			// Отражение по диагонали
			FemMath.mirror(_Rl);

			// Создание матрицы трансформации
			_V = FemMath.getMatrix(6, 6);

			// Заполнение матрицы трансформации
			// http://window.edu.ru/resource/480/79480/files/МКЭ%20(теория%20и%20практика).pdf
			if (hasStartJoint && hasEndJoint)
			{
				_V[0][0] = cosA;
				_V[0][1] = sinA;
				_V[1][0] = -sinA;
				_V[1][1] = cosA;
				_V[2][2] = 0.001;
				_V[3][3] = cosA;
				_V[3][4] = sinA;
				_V[4][3] = -sinA;
				_V[4][4] = cosA;
				_V[5][5] = 0.001;
			}
			else if (hasStartJoint)
			{
				_V[0][0] = cosA;
				_V[0][1] = sinA;
				_V[1][0] = -sinA;
				_V[1][1] = cosA;
				_V[2][2] = 0.001;
				_V[3][3] = cosA;
				_V[3][4] = sinA;
				_V[4][3] = -sinA;
				_V[4][4] = cosA;
				_V[5][5] = 1;
			}
			else if (hasEndJoint)
			{
				_V[0][0] = cosA;
				_V[0][1] = sinA;
				_V[1][0] = -sinA;
				_V[1][1] = cosA;
				_V[2][2] = 1;
				_V[3][3] = cosA;
				_V[3][4] = sinA;
				_V[4][3] = -sinA;
				_V[4][4] = cosA;
				_V[5][5] = 0.001;
			}
			else if (!hasStartJoint && !hasEndJoint)
			{
				_V[0][0] = cosA;
				_V[0][1] = sinA;
				_V[1][0] = -sinA;
				_V[1][1] = cosA;
				_V[2][2] = 1;
				_V[3][3] = cosA;
				_V[3][4] = sinA;
				_V[4][3] = -sinA;
				_V[4][4] = cosA;
				_V[5][5] = 1;
			}

			// Расчет матрицы жесткости стержня в общей системе координат
			_Rg = FemMath.multiplyMatrix(
				FemMath.multiplyMatrix(FemMath.transpose(_V), _Rl), _V);
		}

		/**
		 * Вычисляет вектор узловых перемещений стержня в местной системе координат.
		 */
		public function calcLocalOffset():void
		{
			_zl = FemMath.multiplyMatrix(_V, _zg);
		}

		/**
		 * Вычисляет вектор внутренних сил стержня в местной системе координат.
		 */
		public function calcLocalForce():void
		{
			_rl = FemMath.multiplyMatrix(_Rl, _zl);

			_rl[0] = _rl[0] * -1;
			_rl[2] = _rl[2] * -1;
			_rl[4] = _rl[4] * -1;

			// Округление чисел до 4 знака после запятой.
			for (var i:int = 0; i < _rl.length; i++)
				_rl[i] = FemMath.roundDecimal(_rl[i], 4);
		}

		/**
		 * Удаляет стержень.
		 */
		public function free():void
		{
			material = null;
			from = null;
			to = null;
			id = -1;

			_Rl = null;
			_Rg = null;
			_V = null;
			_zl = null;
			_zg = null;
			_rl = null;
		}

		public function toString():String
		{
			return "FemRod{id=" + String(id) + ",material=" + String(material) +
				",from=" + String(from) + ",to=" + String(to) + "}";
		}

		//----------------------------------------------------------------------
		//
		//  GET/SET METHODS
		//
		//----------------------------------------------------------------------

		/**
		 * Матрица жесткости стержня в общей системе координат.
		 */
		public function get Rg():Array
		{
			return _Rg;
		}

		/**
		 * @private
		 */
		public function set Rg(value:Array):void
		{
			_Rg = value;
		}

		/**
		 * Вектор узловых перемещений в местной системе координат.
		 */
		public function get zl():Array
		{
			return _zl;
		}

		/**
		 * @return
		 */
		public function set zl(value:Array):void
		{
			_zl = value;
		}

		/**
		 * Вектор узловых перемещений в общей системе координат.
		 */
		public function get zg():Array
		{
			return _zg;
		}

		/**
		 * @private
		 */
		public function set zg(value:Array):void
		{
			_zg = value;
		}

		/**
		 * Вектор концевых усилий в местной системе координат.
		 */
		public function get rl():Array
		{
			return _rl;
		}
	}
}
