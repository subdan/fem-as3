// =============================================================================
//
//  Библиотека классов для расчета плоской
//  стержневой конструкции методом конечных элементов.
//  Copyright (c) 2012 Субботин Даниил (subdan@me.com)
//
// =============================================================================
package ru.subdan.fem
{
	/**
	 * Класс описывает материал стержня.
	 */
	public class FemMaterial
	{
		/**
		 * Идентификатор материала.
		 */
		public var id:int;

		/**
		 * Модуль упругости материала стержня, Па.
		 */
		public var e:Number;

		/**
		 * Площадь поперечного сечения стержня, м^2.
		 */
		public var f:Number;

		/**
		 * Момент инерции материала стрежня, м^4.
		 */
		public var i:Number;

		/**
		 * @constructor
		 * @param id Идентификатор материала.
		 * @param e Модуль упругости материала стержня, Па.
		 * @param f Площадь поперечного сечения стержня, м^2.
		 * @param i Момент инерции материала стрежня, м^4.
		 */
		public function FemMaterial(id:int, e:Number, f:Number, i:Number)
		{
			this.id = id;
			this.e = e;
			this.f = f;
			this.i = i;
		}

		public function toString():String
		{
			return "FemMaterial{id=" + String(id) + ",e=" + String(e) +
				       ",f=" + String(f) + ",i=" + String(i) + "}";
		}
	}
}
