# Sistema Inteligente de Gestión de Inventario — Supermercado Oriental

Sistema de análisis y predicción de inventario que combina modelos de Machine Learning y algoritmos de búsqueda inteligente (backend en Python) con una aplicación de escritorio (Flutter/Windows) para la gestión diaria de inventario, ventas, reentrenamiento del modelo y un asistente conversacional con IA.

---

## Arquitectura general

El proyecto tiene dos partes que comparten la misma base de datos SQLite (`data/inventario.db`):

1. **Backend de Machine Learning (Python)** — pipeline de preprocesamiento, procesamiento, entrenamiento de modelos, agente de reglas y búsqueda de prioridad. Se ejecuta como script (`src/main.py`) o directamente desde la app de escritorio con el botón **Reentrenar**.
2. **Aplicación de escritorio (Flutter, Windows)** — interfaz gráfica para gestionar inventario y ventas, disparar el reentrenamiento del modelo, visualizar reportes/gráficos, abrir un dashboard de Power BI y conversar con un asistente de IA sobre el estado del inventario.

La gestión del inventario y las ventas se realiza **directamente desde la app de escritorio**, que escribe sobre `inventario.db`. No se usa Excel como fuente de datos del sistema.

---

## Estructura del proyecto

```
LRPD_sI/                              # Backend de Machine Learning (Python)
├── data/
│   └── inventario.db                 # Base de datos SQLite (inventario, ventas, tablas derivadas)
├── outputs/
│   ├── graficos/
│   │   ├── demanda_real_vs_predicha.png
│   │   ├── matriz_confusion.png
│   │   └── arbol_decision.png
│   └── reportes/
│       ├── metricas_modelos.csv
│       ├── recomendaciones.csv
│       ├── tendencias_importacion.csv
│       ├── productos_a_importar.csv
│       ├── productos_a_reducir.csv
│       └── productos_priorizados.csv
├── src/
│   ├── init_db.py             # Creación de tablas (inventario, ventas) si no existen
│   ├── preprocesamiento.py    # Limpieza, normalización y clasificación de rotación
│   ├── procesamiento.py       # Cálculo de variables derivadas (urgencia, riesgo de vencimiento)
│   ├── modelos.py             # Regresión lineal y árbol de decisión
│   ├── agente.py              # Agente de reglas para recomendaciones
│   ├── busqueda.py            # Best-First Search para priorización
│   └── main.py                # Punto de entrada del pipeline completo
├── requirements.txt
└── README.md

lrpd_desktop/                         # Aplicación de escritorio (Flutter)
├── lib/
│   ├── main.dart                  # Punto de entrada, navegación entre pantallas
│   ├── inventario_screen.dart     # Gestión de inventario
│   ├── ventas_screen.dart         # Registro de ventas
│   ├── analisis_screen.dart       # Reportes, gráficos y botón de reentrenamiento
│   ├── chat_screen.dart           # Asistente de IA sobre el inventario
│   ├── db_service.dart            # Acceso a inventario.db
│   └── services/
│       ├── python_service.dart    # Ejecuta el pipeline de Python (src/main.py)
│       ├── reportes_service.dart  # Lectura de CSVs y gráficos generados
│       └── chat_service.dart      # Integración con la API de Claude
├── config/
│   └── anthropic_api_key.txt      # API key del chatbot (no se versiona, ver más abajo)
└── pubspec.yaml
```

---

## Requisitos

### Backend (Python)
- Python 3.10 o superior
- Instalar dependencias:

```bash
pip install -r requirements.txt
```

### Aplicación de escritorio (Flutter)
- Flutter SDK (canal estable) con soporte para Windows Desktop habilitado
- Python instalado y accesible en la ruta configurada en `PythonService` (`lib/services/python_service.dart`)

```bash
cd lrpd_desktop
flutter pub get
flutter run -d windows
```

---

## Ejecución

### 1. Inicializar la base de datos (solo la primera vez)

La primera vez que corre `src/main.py`, si la tabla `ventas` no existe, se crea automáticamente ejecutando `src/init_db.py`. No se requiere ningún paso manual adicional.

### 2. Uso diario — desde la app de escritorio

La app de escritorio es el punto de entrada normal del sistema:

1. **Inventario** — alta, edición y consulta de productos (escribe directo en `inventario.db`).
2. **Ventas** — registro de ventas nuevas.
3. **Análisis** — muestra reportes y gráficos generados por el pipeline; incluye el botón **Reentrenar**, que ejecuta `src/main.py` completo y refresca los reportes automáticamente al terminar.
4. **Chatbot** — asistente de IA para hacer preguntas en lenguaje natural sobre el inventario actual (ver sección más abajo).

### 3. Ejecución manual del pipeline (opcional)

También se puede correr el pipeline completo desde la terminal, sin la app de escritorio:

```bash
python src/main.py
```

Esto corre en orden:
1. **Preprocesamiento** — limpieza, normalización y clasificación de nivel de rotación (basado en ventas reales de los últimos 90 días)
2. **Procesamiento** — cálculo de índice de rotación, urgencia de stock y riesgo de vencimiento
3. **Modelos ML** — entrenamiento de regresión lineal y árbol de decisión
4. **Agente inteligente** — generación de recomendaciones por reglas
5. **Best-First Search** — priorización de productos por reposición

---

## Modelos utilizados

### Regresión Lineal
- **Objetivo:** predecir el `indice_rotacion` de cada producto
- **Features:** `stock_actual`, `stock_minimo`, `cantidad_vendida`, `dias_para_vencer`, `urgencia_stock`
- **Preprocesamiento:** escalado con `StandardScaler`
- **¿Por qué regresión lineal y no red neuronal?** El dataset es pequeño y las relaciones entre variables son aproximadamente lineales. Una red neuronal requeriría miles de registros para generalizar bien y añadiría complejidad innecesaria sin mejora significativa en este contexto.

### Árbol de Decisión
- **Objetivo:** clasificar el `nivel_rotacion` (Alta / Media / Baja)
- **Features:** `stock_actual`, `stock_minimo`, `dias_para_vencer`, `urgencia_stock`
- **Parámetros:** `max_depth=3`, `min_samples_leaf=5`
- **¿Por qué árbol de decisión y no SVM?** El árbol produce reglas interpretables (ej. "si stock_actual ≤ 44.5 entonces..."), lo cual es clave para que el negocio entienda y confíe en las decisiones. Un SVM es una caja negra que no permite esa interpretabilidad.

> Las métricas exactas (MSE, R², Accuracy, F1) varían en cada reentrenamiento según los datos de inventario y ventas cargados, y quedan disponibles en `outputs/reportes/metricas_modelos.csv`.

### Best-First Search
- **Objetivo:** priorizar productos para reposición
- **Función heurística h(n):** `0.5 × rotación + 0.3 × demanda_norm + 0.2 × urgencia_stock`
- **¿Por qué Best-First y no A\*?** A\* requiere un grafo con costos reales de transición g(n). En este problema no existe un grafo de nodos, solo una lista de productos a ordenar por prioridad. Best-First Search con h(n) es suficiente y más eficiente para este caso.

---

## Outputs generados

| Archivo | Descripción |
|---|---|
| `metricas_modelos.csv` | MSE, R² de regresión y Accuracy, F1 del árbol |
| `recomendaciones.csv` | Acción recomendada por producto (reabastecimiento, sobrestock, promoción) |
| `tendencias_importacion.csv` | Decisión de importación por categoría (aumentar/reducir/mantener) |
| `productos_a_importar.csv` | Productos de alta rotación con stock crítico, con cantidad sugerida a importar |
| `productos_a_reducir.csv` | Productos de baja rotación con sobrestock persistente |
| `productos_priorizados.csv` | Productos ordenados por score de prioridad (Best-First Search) |
| `demanda_real_vs_predicha.png` | Gráfico de dispersión real vs predicho (regresión) |
| `matriz_confusion.png` | Matriz de confusión del árbol de decisión |
| `arbol_decision.png` | Visualización del árbol de decisión |

---

## Agente inteligente

El agente aplica reglas de negocio sobre cada producto y también agrupa por categoría para decisiones de importación:

| Condición | Acción |
|---|---|
| Rotación Alta + stock < stock mínimo | Reabastecimiento urgente |
| Rotación Baja + stock > 3× stock mínimo | Alerta de sobrestock |
| Días para vencer < 15 | Promocionar producto |
| Ninguna condición anterior | Monitorear |

---

## Dashboard de Power BI (opcional)

La app de escritorio incluye un botón **Power BI** en la pantalla de Análisis que abre un archivo `.pbix` (`outputs/reportes/dashboard.pbix`) con el programa asociado en Windows (Power BI Desktop debe estar instalado). El dashboard se conecta a los CSVs generados en `outputs/reportes/`; tras reentrenar, hay que usar **Actualizar** dentro de Power BI para reflejar los datos nuevos.

---

## Asistente de IA (Chatbot)

La pestaña **Chatbot** de la app de escritorio permite hacer preguntas en lenguaje natural sobre el inventario (ej. *"¿qué productos hay que reabastecer con urgencia?"*), usando la API de Claude (Anthropic). El asistente responde únicamente en base a los reportes generados por el pipeline (`outputs/reportes/`), sin inventar información fuera de esos datos.

Requiere una API key de [console.anthropic.com](https://console.anthropic.com), configurable desde la propia app (se guarda localmente en `config/anthropic_api_key.txt`, que **no debe subirse al repositorio**).

---

## Notas de configuración

- `lib/services/python_service.dart` define la ruta al ejecutable de Python (`comandoPython`) y al proyecto (`rutaProyecto`) — ajustar según el entorno donde se despliegue la app.
- `config/anthropic_api_key.txt` contiene credenciales sensibles: debe agregarse a `.gitignore`.
