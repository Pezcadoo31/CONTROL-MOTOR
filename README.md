# Control de Velocidad para un Motor DC con PID

## Introducción
En este proyecto se implementó un sistema de control PID digital para regular la velocidad de un motor de corriente continua. Utilizando un Arduino Uno y un encoder, se controló la velocidad del motor a través de la modulación por ancho de pulso (PWM) y un puente H L298N.

## Objetivo
Desarrollar un sistema de control de velocidad para el motor DC mediante un controlador PID digital, logrando mantener la velocidad deseada bajo diferentes condiciones de carga.

## Componentes del Sistema
- **Arduino Uno:** Microcontrolador para la ejecución del algoritmo de control.
- **Motor DC con Encoder:** Motor de 12V con un encoder que proporciona retroalimentación de velocidad.
- **Puente H L298N:** Controlador de potencia para manejar la dirección y velocidad del motor.

## Diseño del Sistema
El sistema de control PID fue diseñado y ajustado mediante el método de ajuste manual, permitiendo optimizar los parámetros de respuesta del sistema.

### Parámetros del Motor
- Voltaje de operación: 12V
- Velocidad nominal: 180 rpm
- Resolución del encoder: 341.2 PPR

## Implementación
1. **Control de Dirección y Velocidad:** Se utilizó Arduino para controlar la dirección del motor y ajustar la velocidad mediante PWM.
2. **Retroalimentación del Encoder:** El encoder se usó para medir la velocidad actual del motor y proporcionar retroalimentación al controlador PID.
3. **Ajuste del PID:** Se optimizaron los parámetros del controlador PID (proporcional, integral y derivativo) para mantener la estabilidad y precisión en la velocidad.

## Mejoras Potenciales
Este proyecto puede ser mejorado integrando un sistema de aprendizaje automático para ajustar automáticamente los parámetros PID en tiempo real, optimizando la respuesta ante cambios en las condiciones de carga. Además, se podrían explorar otros controladores, como el control adaptativo, para mejorar la robustez y eficiencia del sistema.
