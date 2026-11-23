# PR4: Práctica de compilación modular

## Introducción

Esta actividad permite ejercitar la construcción de un programa modular en C, primero mediante comandos de compilación y enlace y luego mediante un Makefile. Se comprobará que ambas formas producen los mismos resultados y que la construcción automática responde correctamente a cambios en archivos fuente y cabeceras.

La práctica utiliza un programa completo y correcto. No se debe modificar el código: el trabajo consiste en identificar los archivos necesarios, construir los comandos y completar un Makefile a partir de una estructura básica, aplicando lo aprendido en CMO y MAK.

### Prerrequisitos

- Haber completado CMO y MAK
- Distinguir declaraciones, implementaciones y archivos objeto
- Saber interpretar reglas de un Makefile y editar recetas con tabulaciones en Vim
- Tener disponibles Bash, GNU Make, `gcc`, `file`, `diff` y `timeout` en Linux

### Objetivo general

- Aplicar compilación separada, enlace y Makefiles para construir y verificar un programa modular

### Objetivos específicos

- Construir un ejecutable a partir de archivos objeto
- Completar un Makefile con variables, una regla patrón y targets de construcción y limpieza
- Comprobar la construcción incremental y el seguimiento de cambios en cabeceras
- Verificar el programa con los test cases y limpiar los archivos generados sin eliminar fuentes ni casos de prueba

### Estructura inicial

```text
workspace/
├── code/
│   ├── Makefile
│   ├── main.c
│   ├── request.h
│   ├── parser.c
│   ├── parser.h
│   ├── capacity.c
│   ├── capacity.h
│   ├── priority.c
│   ├── priority.h
│   ├── report.c
│   └── report.h
├── tests/
│   ├── test001.in
│   ├── test001.expected
│   ├── ...
│   ├── test004.in
│   └── test004.expected
└── scripts/
    ├── tests-run.sh
    └── check.sh
```

Se entrega el programa de evacuaciones utilizado en MAK, junto con cuatro test cases y un Makefile con una estructura básica. Las variables y reglas pendientes están indicadas mediante comentarios `TODO`. Los archivos fuente y los resultados esperados están completos y no requieren correcciones.

## Contexto

Una base de la Alianza Rebelde coordina solicitudes de evacuación. Cada solicitud informa la base de origen, la cantidad de personas que necesitan salir, el número de naves disponibles, la cantidad de personas que puede transportar cada nave y una prioridad numérica.

Para esta gestión, un programa calcula la capacidad total de las naves y la compara con la cantidad de personas. Informa `OK` si la capacidad es suficiente, incluyendo el caso en que alcance exactamente, y `ALERTA` si faltan cupos. Además, clasifica la prioridad como `NORMAL` para valores menores que 60, `ALTA` entre 60 y 89 y `CRITICA` desde 90.

La entrada comienza con la cantidad de solicitudes. Luego se entrega una solicitud por línea, con los campos en el orden descrito. Por ejemplo:

```text
1
Echo 450 3 200 75
```

En este caso hay 600 cupos para 450 personas. La salida esperada es:

```text
Solicitud 001: OK | base=Echo | capacidad=600/450 | prioridad=ALTA
```

Todas las entradas entregadas son válidas. Los tests incluyen capacidad suficiente, insuficiente y exacta, además de distintas prioridades.

## Actividad

### 1. Construir manualmente

#### 1.1. Identificar y compilar los módulos

Desde la raíz del repositorio, entrar a `workspace/code` y revisar las cabeceras y las llamadas entre módulos. `main.c` coordina el programa, `parser.c` lee las solicitudes, `capacity.c` revisa los cupos, `priority.c` clasifica la prioridad y `report.c` imprime el resultado. `request.h` define los datos compartidos.

Compilar cada `.c` a su propio `.o`, sin realizar todavía el enlace. Utilizar `gcc` con `-Wall`, `-Wextra`, `-Werror`, `-std=c11`, `-g` y `-O0`.

Si el compilador informa un problema, revisar el comando, las rutas y los nombres antes de modificar cualquier archivo. El código entregado no requiere correcciones.

#### 1.2. Enlazar y probar

Enlazar los cinco objetos para producir `evacuacion_manual`. Ejecutarlo utilizando `../tests/test001.in` como entrada mediante `<`, guardar la salida en `../tests/test001.out` y compararla con el `.expected` correspondiente mediante `diff`.

Si la salida no coincide, revisar los comandos de compilación y ejecución y los archivos utilizados antes de repetir la prueba. Conservar `evacuacion_manual` durante el resto de la actividad.

### 2. Completar y comprobar el Makefile

#### 2.1. Completar las variables y las reglas

Desde `workspace/code`, abrir el Makefile con Vim. La plantilla contiene los nombres de las variables, el target `all`, el target `clean` y la declaración `.PHONY`. Completar las variables reemplazando los comentarios `TODO` por sus valores, indicar la dependencia de `all` y escribir las reglas de enlace y compilación, junto con la receta de limpieza. La variable `CPPFLAGS` puede permanecer vacía. Se puede consultar la guía de MAK como referencia.

El Makefile debe cumplir estas condiciones:

- `make` y `make all` construyen un ejecutable llamado `evacuacion`
- Cada archivo fuente se compila a su propio objeto mediante una regla patrón
- Se utilizan variables para el compilador, los flags, el ejecutable, los objetos y los archivos de dependencias, junto con las variables automáticas en las recetas
- La compilación utiliza `gcc` con los mismos flags solicitados en 1.1
- El ejecutable se construye enlazando los cinco objetos
- Los archivos `.d` se generan e incorporan para reconocer cambios en las cabeceras
- `clean` elimina `evacuacion`, los `.o`, los `.d` y las salidas `.out`, `.err` y `.diff` de los tests
- `clean` conserva las fuentes, cabeceras, Makefile, `.in`, `.expected` y `evacuacion_manual`
- Los targets que representan acciones se declaran con `.PHONY`

Las recetas deben comenzar con una tabulación real. Si es necesario revisar la configuración de Vim, consultar el anexo sobre tabulaciones de la guía MAK.

Una vez completado el Makefile, ejecutar el target `clean` antes de la primera construcción automática: los objetos generados manualmente en la actividad 1 todavía no tienen archivos `.d`. Luego construir el programa y comprobar que se genere `evacuacion`. Si aparece un error, leer el mensaje y revisar las variables, las reglas y las tabulaciones antes de repetir la construcción.

Agregar permiso de ejecución para el propietario a `../scripts/tests-run.sh`. Ejecutar directamente este script, indicando `./evacuacion` como ejecutable y `../tests` como carpeta de tests. Comprobar que la suite informe cuatro `PASS`. Si aparece `FAIL` o `ERRO`, revisar las salidas, los mensajes y el Makefile antes de repetir las pruebas.

#### 2.2. Revisar las dependencias y la limpieza

Sin modificar archivos, repetir la construcción y comprobar que no ejecuta compilaciones ni enlace.

Actualizar la fecha de `capacity.c` mediante `touch` y volver a construir. Debe recompilarse solamente ese módulo y luego volver a enlazarse el ejecutable. Repetir con `request.h`: ahora deben reconstruirse `main.o`, `parser.o`, `capacity.o` y `report.o`, pero conservarse `priority.o`. Relacionar lo observado con las cabeceras que incluye cada módulo.

Si el comportamiento no coincide, revisar las dependencias y los `.d` antes de repetir. Ejecutar nuevamente el script de pruebas para comprobar que el programa mantiene sus resultados.

Finalmente, ejecutar el target `clean` y revisar que elimine solamente los archivos indicados. Volver a construir y ejecutar el script de pruebas para dejar el programa disponible.

### 3. Verificación final

Volver a `workspace` y agregar permiso de ejecución para el propietario a `scripts/check.sh`.

Ejecutar `scripts/check.sh`.
