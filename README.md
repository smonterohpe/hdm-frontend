# hdm-frontend

**Hospital Discharge Manager (HDM)** · Componente Frontend  
nginx · HTML/JS · VM Ubuntu 24.04 · Puerto 80

## Funcionalidades

- 6 KPIs en tiempo real (auto-refresh cada 3 s)
- Tabla de últimas 30 altas con animación de nuevas filas
- Indicador de estado del sistema (cabecera)
- Alerta visual durante los demos de ransomware / human error
- Proxy nginx transparente al backend (puerto 8000)

## Instalación

```bash
sudo bash scripts/install_frontend.sh
```

## Estructura

```
hdm-frontend/
├── html/index.html          ← Aplicación completa (single file)
├── nginx/hdm-frontend.conf  ← Configuración nginx
└── scripts/install_frontend.sh
```
