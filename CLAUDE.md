# Home Assistant Configuration

Instructions for Claude Code when working with Home Assistant.

## File Structure

YAML configurations are primarily stored in `/config/packages/*.yaml`.
When searching, check all yaml files in `/config/*.yaml` and the packages folder.

Configurations and automations should be in self-contained files in the packages/ folder.

## Getting Entity/Device Information

**Prefer `ha-ws` for detailed lookups** - it provides full context:

```bash
# Get comprehensive entity info (registry, state, related automations/scenes)
ha-ws entity get <entity_id>

# Get comprehensive device info (all entities, related automations/scenes)
ha-ws device get <device_id>

# Use --json for full raw data
ha-ws --json entity get sensor.temperature
```

For quick state checks, `ha-api` is faster:
```bash
ha-api state light.kitchen      # Just the state value
ha-api attr sensor.temperature  # Just attributes
```

## REST API CLI Tool

Use `ha-api` for REST API interactions:

```bash
ha-api <command> [options]
```

### Commands

| Command | Description |
|---------|-------------|
| `states [filter]` | List all entities (optional grep filter) |
| `state <entity_id>` | Get state of specific entity |
| `domains` | List entity counts by domain |
| `devices <device_class>` | Find entities by device_class (motion, door, temperature, etc.) |
| `search <pattern>` | Search entity IDs by pattern |
| `call <domain> <service>` | Call a service |
| `attr <entity_id>` | Show all attributes of an entity |
| `history <entity_id> [hrs]` | Get history for entity (default: 24 hours) |
| `get <endpoint>` | GET any API endpoint |
| `post <endpoint> [json]` | POST to any API endpoint with optional JSON body |

### Examples

```bash
ha-api devices motion           # Find all motion sensors
ha-api devices occupancy        # Find occupancy sensors
ha-api search kitchen           # Find entities containing "kitchen"
ha-api state light.living_room  # Get current state
ha-api attr sensor.temperature  # Show all attributes
ha-api call light turn_on       # Call a service
```

### Generic API Access

For any API endpoint not covered by the built-in commands:

```bash
ha-api get config                    # GET /api/config
ha-api get events                    # GET /api/events
ha-api get services                  # GET /api/services
ha-api get error_log                 # GET /api/error_log
ha-api post services/light/turn_on '{"entity_id":"light.living_room"}'
```

## Checking Configuration

Before reloading, always validate the configuration:

```bash
ha core check --no-progress --raw-json
```

Expected success response: `{"result":"ok","data":{}}`

## Reloading YAML Configuration

After making changes to YAML files, ask the user if they want to reload the configuration.

To reload all YAML-configured domains:

```bash
ha-api call homeassistant reload_all
```

Returns `[]` on success.

### Selective Reloads

| Domain | Command |
|--------|---------|
| Automations | `ha-api call automation reload` |
| Scripts | `ha-api call script reload` |
| Scenes | `ha-api call scene reload` |
| Groups | `ha-api call group reload` |
| Input booleans | `ha-api call input_boolean reload` |
| Input numbers | `ha-api call input_number reload` |
| Input selects | `ha-api call input_select reload` |
| Input texts | `ha-api call input_text reload` |
| Timers | `ha-api call timer reload` |
| Template entities | `ha-api call template reload` |

### HomeKit

HomeKit picks up entity changes (adds/removes) with just a YAML reload - no integration reload or restart needed.

## WebSocket CLI Tool

Use `ha-ws` for registry management and WebSocket API operations:

```bash
ha-ws <command> [options]
```

### Registry Commands

```bash
# Entity Registry
ha-ws entity list [filter]              # List entities (filter by ID)
ha-ws entity get <entity_id>            # Get entity details
ha-ws entity update <id> key=value...   # Update entity
ha-ws entity remove <entity_id>         # Remove entity

# Device Registry
ha-ws device list [filter]              # List devices
ha-ws device get <device_id>            # Get device details
ha-ws device update <id> key=value...   # Update device
ha-ws device remove <device_id>         # Remove device

# Area Registry
ha-ws area list                         # List all areas
ha-ws area create <name>                # Create new area
ha-ws area update <id> key=value...     # Update area
ha-ws area delete <area_id>             # Delete area
```

### State & Service Commands

```bash
ha-ws state <entity_id>                 # Get current state
ha-ws states [domain]                   # List states (optional domain filter)
ha-ws call <domain>.<service> [data]    # Call a service
ha-ws services [domain]                 # List available services
```

### Examples

```bash
# Rename an entity
ha-ws entity update light.old_name new_entity_id=light.new_name

# Set entity icon and clear name (inherit from device)
ha-ws entity update light.lamp icon=mdi:floor-lamp name=none

# Set device area and name
ha-ws device update abc123 area_id=kitchen name_by_user="Kitchen Light"

# Call a service
ha-ws call light.turn_on entity_id=light.kitchen brightness=255

# Get state with JSON output
ha-ws --json state sensor.temperature
```

### Value Syntax

| Syntax | Result |
|--------|--------|
| `key=value` | String |
| `key=123` | Integer |
| `key=true` / `key=false` | Boolean |
| `key=null` / `key=none` | None (clears field) |
| `key="quoted string"` | String with spaces |

### Raw WebSocket

For any WebSocket message type:

```bash
ha-ws raw config/entity_registry/list
ha-ws raw config/core/info
ha-ws raw config/entity_registry/get entity_id=light.kitchen           # key=value params
ha-ws raw config_entries/ignore_flow '{"flow_id":"X","title":"Y"}'  # or a JSON object
```

## Full Restart (if needed)

For changes that require a full restart:

```bash
ha core restart --no-progress --raw-json
```

## Lovelace Dashboard Sync

The `.storage/lovelace` file is managed by HA in memory. Direct file edits won't take effect until synced.

**Workflow:**
```bash
# 1. Edit the lovelace file directly
# 2. Push to HA (no restart needed)
lovelace-sync
# 3. Refresh browser/app to see changes
```

Prefer direct JSON edits over writing Python scripts - simpler and faster.

## Template Entities (Modern Syntax)

**IMPORTANT:** Always use the modern `template:` syntax. The legacy `platform: template` syntax is deprecated.

### Modern Format

```yaml
template:
  - sensor:
      - name: "My Sensor"
        unique_id: my_sensor
        unit_of_measurement: "W"
        icon: mdi:gauge
        state: >
          {{ states('sensor.other')|float + 10 }}
    binary_sensor:
      - name: "My Binary Sensor"
        unique_id: my_binary_sensor
        delay_on:
          minutes: 5
        state: >
          {{ states('sensor.value')|int > 100 }}
```

### Key Differences from Legacy

| Legacy (Deprecated) | Modern |
|---------------------|--------|
| `sensor: platform: template` | `template:` with `sensor:` list |
| `value_template:` | `state:` |
| `icon_template:` | `icon:` |
| `friendly_name:` | `name:` |
| `delay_on: '01:30:00'` | `delay_on: { hours: 1, minutes: 30 }` |
