#fem-as3
**Версия 0.5**

fem-as3 это библиотека классов написанная на языке ActionScript 3 реализующая
метод конечных элементов для расчета плоской стержневой конструкции.

## В будущем будет реализовано
- Добавление шарниров в узлы
- Добавление равномерно распределенной нагрузки

## Как использовать

Создание конструкции:
```as3
var co:FemConstruction = new FemConstruction();
```

> Внимание! Перед вводом данных убедитесь, что они соответствуют
> единицам измерения: м, м^2, м^4, Н, Па.

Создание необходимых материалов:
```as3
var defaultMaterial:FemMaterial = new FemMaterial(
    "Стальной стержень",   // Название стержня
    2 * Math.pow(10, 11),  // Модуль упругости, Па
    0.01,                  // Площадь поперечного сечения, м^2
    8.3 * Math.pow(10, -8) // Момент инерции, м^4
);
```

Добавление узлов в конструкцию:
```as3
var node1:FemNode = co.addNode(new FemNode(1, new Point(0, 0), FemNode.TYPE_HING_FIXED, 0));
var node2:FemNode = co.addNode(new FemNode(2, new Point(0, 4.8), FemNode.TYPE_HING_MOVED, 90, 0, 0, 10000));
var node3:FemNode = co.addNode(new FemNode(3, new Point(4, 0), FemNode.TYPE_HING_MOVED, 90, 0, 0, 15000));
var node4:FemNode = co.addNode(new FemNode(4, new Point(4, 4.8), FemNode.TYPE_HING_MOVED, 90, 0, -10000));
```

Добавление стержней в конструкцию:
```as3
co.addRod(new FemRod(1, defaultMaterial, node1, node2));
co.addRod(new FemRod(2, defaultMaterial, node1, node3));
co.addRod(new FemRod(3, defaultMaterial, node3, node4));
```

Выполнение расчета и получение ответа:
```as3
var answer:Array = co.calculateAll();
FemMath.traceMatrix(answer);
```

## Информация о версиях
Версия 0.5 Начальная версия.
