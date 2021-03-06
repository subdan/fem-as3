#fem-as3
**Версия 0.9**

fem-as3 — это библиотека классов написанная на языке ActionScript 3 реализующая метод конечных элементов для расчета плоской стержневой конструкции. Библиотека разрабатывалась в рамках курсового проекта по вычислительной механике и используется в Flash приложении [RodCalc](http://ninasb.ru/rodcalc.html) которое позволяет визуально построить стержневую систему, рассчитать ее и визуально представить результаты расчета.

## Как использовать

###Создание конструкции
```as3
var co:FemConstruction = new FemConstruction();
```

###Создание необходимых материалов
```as3
var defaultMaterial:FemMaterial = new FemMaterial(
    1, // Идентификатор материала
    2 * Math.pow(10, 11),  // Модуль упругости, Па
    0.01,                  // Площадь поперечного сечения, м^2
    8.3 * Math.pow(10, -8) // Момент инерции, м^4
);
```

###Добавление узлов в конструкцию
> Описание классов, их методов и свойств смотрите в [документации](http://subdan.github.com/fem-as3/).

```as3
var node1:FemNode = co.addNode(new FemNode(1, new Point(0, 0), FemNode.TYPE_HING_FIXED, 0));
var node2:FemNode = co.addNode(new FemNode(2, new Point(0, 4.8), FemNode.TYPE_HING_MOVED, 90, 0, 0, 10000));
var node3:FemNode = co.addNode(new FemNode(3, new Point(4, 0), FemNode.TYPE_HING_MOVED, 90, 0, 0, 15000));
var node4:FemNode = co.addNode(new FemNode(4, new Point(4, 4.8), FemNode.TYPE_HING_MOVED, 90, 0, -10000));
```
В начале указывается идентификатор узла. Затем координаты. Далее тип узла:

- FemNode.TYPE_HING_FIXED — Шарнирно неподвижный
- FemNode.TYPE_HING_MOVED — Шарнирно подвижный
- FemNode.TYPE_NONE — Обычный узел
- FemNode.TYPE_HARD — Жесткая заделка

Следующий параметр — это угол поворота узла.

Далее нагрузка по X, по Y и момент, действующий на узел.

###Добавление стержней в конструкцию
```as3
co.addRod(new FemRod(1, defaultMaterial, node1, node2));
co.addRod(new FemRod(2, defaultMaterial, node1, node3));
var rodWithJoints = co.addRod(new FemRod(3, defaultMaterial, node3, node4));
rodWithJoints.hasStartJoint = true; // Шарнир в начале стержня
rodWithJoints.hasEndJoint = true; // Шарнир в конце стержня
var rodWithDistrLoad = co.addRod(new FemRod(4, defaultMaterial, node1, node4));
rodWithDistrLoad.distributetLoad = -10; // Равномерно распределенная нагрузка силой -10
```

###Выполнение расчета
```as3
co.calculateAll();
```

###Получение результата расчета

####Смещение узла
Пример. Смещение 3-го узла:
```as3
trace("Смещение узла 3");
trace(co.getNode(3).offsetX);
trace(co.getNode(3).offsetY);
trace(co.getNode(3).offsetM);
```

####Силовые факторы стержня
Пример. Силовые факторы 2-го стержня:
```as3
trace("Силовые факторы стержня 2");
trace(co.getRod(2).factorNFrom);
trace(co.getRod(2).factorNTo);
trace(co.getRod(2).factorQFrom);
trace(co.getRod(2).factorQTo);
trace(co.getRod(2).factorMFrom);
trace(co.getRod(2).factorMTo);
```

Если на стержень действует распределенная нагрузка, то промежуточные усилия можно посмотреть так:
```as3
trace(co.getRod(2).factorsM);
trace(co.getRod(2).factorsQ);
trace(co.getRod(2).factorsN);
```

## Информация о версиях

Версия 0.9
- Учет равномерно распределенной нагрузки.

Версия 0.8
- Возможность добавления шарнира в начало и конец стержня.

Версия 0.7
- Форматирование результатов расчета.
- Исправлены ошибки.

Версия 0.6
- Улучшен способ предоставления результатов расчета.

Версия 0.5
- Начальная версия.
