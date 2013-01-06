// =============================================================================
//
//  Библиотека классов для расчета плоской
//  стержневой конструкции методом конечных элементов.
//  Copyright (c) 2012 Субботин Даниил (subdan@me.com)
//
// =============================================================================
package ru.subdan.fem
{
	import flash.geom.Point;

	/**
	 * Класс <code>FemNode</code> описывает узел.
	 */
	public class FemNode
	{
		//----------------------------------
		//  STATIC CONSTANTS
		//----------------------------------

		/**
		 * Обычный узел.
		 * Возможны перемещения по оси X, Y и поворот узла.
		 */
		public static const TYPE_NONE:int = 0;

		/**
		 * Заделка.
		 * Перемещения и поворот узла невозможны.
		 */
		public static const TYPE_HARD:int = 1;

		/**
		 * Шаринирно-подвижный.
		 * Возможен поворот узла и перемещение узла по оси X или Y
		 * (в зависимости от начального угла поворота узла).
		 */
		public static const TYPE_HING_MOVED:int = 2;

		/**
		 * Шарнирно-неподвижный.
		 * Возможен только поворот узла.
		 */
		public static const TYPE_HING_FIXED:int = 3;

		//----------------------------------
		//  PUBLIC VARIABLES
		//----------------------------------

		/**
		 * Координаты узла в метрах.
		 */
		public var pos:Point;

		/**
		 * Идентификатор узла.
		 */
		public var id:int;

		/**
		 * Тип узла (см. публичные константы).
		 */
		public var type:int;

		/**
		 * Угол поворота узла в градусах:
		 * 0 - узел направлен вверх;
		 * 90 - узел направлен влево;
		 * 180 - узел направлен вниз;
		 * 270 - узел направлен вправо.
		 */
		public var angle:int;

		/**
		 * Составляющая нагрузки вдоль оси X, H.
		 */
		public var loadX:Number;

		/**
		 * Составляющая нагрузки вдоль оси Y, H.
		 */
		public var loadY:Number;

		/**
		 * Момент, действующий на узел, H * м.
		 */
		public var loadM:Number;

		/**
		 * Смещение узла по оси X после выполнения расчета.
		 */
		public var offsetX:Number;

		/**
		 * Смещение узла по оси Y после выполнения расчета.
		 */
		public var offsetY:Number;

		/**
		 * Смещение узла по моменту после выполнения расчета.
		 */
		public var offsetM:Number;

		/**
		 * @constructor
		 * @param id Идентификатор узла.
		 * @param pos Координаты узла в метрах.
		 * @param type Тип узла (см. публичные константы).
		 * @param angle Угол поворота узла в градусах.
		 * @param loadX Составляющая нагрузки вдоль оси X, H.
		 * @param loadY Составляющая нагрузки вдоль оси Y, H.
		 * @param loadM Момент, действующий на узел, H * м.
		 */
		public function FemNode(id:int, pos:Point, type:int, angle:int = 0,
		                        loadX:Number = 0, loadY:Number = 0,
		                        loadM:Number = 0)
		{
			this.id = id;
			this.pos = pos;
			this.type = type;
			this.angle = angle;
			this.loadX = loadX;
			this.loadY = loadY;
			this.loadM = loadM;
		}

		public function toString():String
		{
			return "FemNode{id=" + String(id) + "pos=" + String(pos) +
				       ",type=" + String(type) + ",angle=" + String(angle) +
				       ",loadX=" + String(loadX) + ",loadY=" + String(loadY) +
				       ",loadM=" + String(loadM) + "}";
		}
	}
}
