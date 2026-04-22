# Zentra Agent — Distribución Linux (GitHub)

## Estructura del repo

```
zentra-agent/
  install.sh                        ← script que ejecuta el cliente
  build/
    build_deb.sh                    ← genera el .deb (corres tú en tu máquina)
    zentra-agent-deb/               ← estructura del paquete
```

---

## Flujo de trabajo (tu lado)

### 1. Obtener el binario de Zabbix Agent 2

En Ubuntu 22.04 (tu servidor Azure o WSL2):

```bash
# Agregar repo oficial de Zabbix
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb
sudo apt update

# Descargar sin instalar (solo el .deb)
apt download zabbix-agent2

# Extraer el binario
dpkg-deb -x zabbix-agent2_*.deb /tmp/zabbix-extracted
# El binario está en: /tmp/zabbix-extracted/usr/sbin/zabbix_agent2
```

### 2. Construir el .deb de Zentra

```bash
# Clonar este repo
git clone https://github.com/nuanet/zentra-agent.git
cd zentra-agent

# Copiar el binario extraído
cp /tmp/zabbix-extracted/usr/sbin/zabbix_agent2 build/zentra-agent-deb/usr/sbin/zentra_agent2

# Dar permisos a scripts DEBIAN
chmod 755 build/zentra-agent-deb/DEBIAN/postinst
chmod 755 build/zentra-agent-deb/DEBIAN/prerm

# Construir el .deb
dpkg-deb --build --root-owner-group build/zentra-agent-deb zentra-agent_7.0.3_amd64.deb
```

### 3. Crear el release en GitHub

```bash
# Con GitHub CLI (recomendado)
gh release create v7.0.3 \
  zentra-agent_7.0.3_amd64.deb \
  --repo nuanet/zentra-agent \
  --title "Zentra Agent v7.0.3" \
  --notes "Release inicial"
```

O manualmente: GitHub → Releases → Draft a new release → subir el .deb.

### 4. Generar el PAT de GitHub

GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens

Permisos mínimos necesarios:
- **Contents:** Read-only (para descargar releases)

Copia el token y reemplaza `ghp_REEMPLAZA_CON_TU_PAT` en `install.sh`.

> ⚠️ El token queda visible en el comando de instalación. Para mitigar:
> - Crea un token dedicado con permisos mínimos (solo lectura de este repo)
> - Rota el token periódicamente
> - Considera usar Azure Blob público para el .deb a futuro

### 5. Subir install.sh al repo

```bash
git add install.sh
git commit -m "Add install script"
git push origin main
```

---

## Flujo del cliente

El cliente ejecuta **un solo comando** como root:

```bash
curl -fsSL https://raw.githubusercontent.com/nuanet/zentra-agent/main/install.sh | sudo bash
```

El script:
1. Verifica arquitectura y OS
2. Descarga el `.deb` desde GitHub Releases (autenticado con PAT)
3. Instala con `dpkg`
4. El `postinst` configura el hostname automáticamente y arranca el servicio
5. Verifica que `zentra-agent` esté activo

---

## Actualizar a una versión nueva

1. Incrementa `Version` en `DEBIAN/control`
2. Reconstruye el `.deb`
3. Crea nuevo release en GitHub (v7.0.4, etc.)
4. Actualiza `PACKAGE_NAME` y `GITHUB_TOKEN` en `install.sh` si es necesario
5. En el cliente: `sudo apt install ./zentra-agent_7.0.4_amd64.deb` o volver a correr el install.sh

---

## Comandos útiles (en el host del cliente)

```bash
systemctl status zentra-agent          # estado del servicio
journalctl -u zentra-agent -f          # logs en tiempo real
cat /etc/zentra/zentra_agent2.conf     # configuración
systemctl restart zentra-agent         # reiniciar
sudo dpkg -r zentra-agent              # desinstalar
```
