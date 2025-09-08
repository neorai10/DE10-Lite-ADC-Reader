# DE10-Lite ADC Reader - 5 Channel Flex Sensor System

FPGA system for reading 5 flex sensors with real-time processing and display on DE10-Lite board.

[![FPGA](https://img.shields.io/badge/FPGA-DE10--Lite-blue.svg)]()
[![Language](https://img.shields.io/badge/Language-VHDL-orange.svg)]()
[![Status](https://img.shields.io/badge/Status-Working-green.svg)]()

## Overview

This project implements a multi-channel ADC reader for flex sensors using the DE10-Lite FPGA board. The system continuously samples 5 analog channels, processes the data, and displays voltage readings on 7-segment displays.

Originally started as a single-channel project, it has been expanded to handle 5 channels simultaneously with averaging calculations and future ESP32 communication capabilities.

## Features

- **Multi-channel ADC**: Reads 5 flex sensors simultaneously (A0-A4)
- **Real-time display**: Shows voltage readings in millivolts
- **Channel selection**: Switch between different sensors for display
- **Averaging system**: Calculates running averages (currently being debugged)
- **Status indicators**: LEDs show system state and operation
- **Modular design**: Clean VHDL architecture with separate components

## Hardware Setup

### Required Components
- DE10-Lite FPGA board (MAX 10)
- 5x Flex sensors (bend sensors)
- 5x 47kΩ resistors (voltage dividers)
- Connecting wires

### Connections
Connect each flex sensor with a 47kΩ pull-down resistor to Arduino pins A0 through A4:

```
Flex Sensor ──┬─── Arduino Pin A0-A4
               │
            47kΩ
               │
              GND
```

### Typical Readings
- Straight sensor: ~1890mV
- Fully bent: ~3700mV
- Range: approximately 1800mV working span

## Usage

### Controls
- **SW[0]**: Master enable (start/stop system)
- **SW[1-5]**: Select which channel to display
- **SW[9]**: Display mode (voltage/calculation result)
- **KEY[0]**: Reset (active low)

### Status LEDs
- **LEDR[0]**: New ADC data available
- **LEDR[1]**: Timing system active
- **LEDR[2]**: ADC reading in progress
- **LEDR[5:3]**: Current channel being read
- **LEDR[9]**: Sample trigger (blinks every 5 seconds)

### Display
The 6-digit 7-segment display shows voltage in millivolts. For example, "001890" represents 1890mV.

## Project Structure

```
src/
├── adc_reader_top.vhd         # Main integration
├── adc_controller.vhd         # Multi-channel ADC control
├── timing_controller.vhd      # 5-second timing
├── averaging_unit.vhd         # Statistical processing
├── channel_selector.vhd       # Display channel selection
├── display_controller.vhd     # 7-segment driver
├── data_handler.vhd          # ADC to voltage conversion
├── calculation_unit.vhd       # Advanced calculations
└── number_sender.vhd         # UART communication

constraints/
├── de10_lite_pin_assignments.tcl
└── adc_reader.sdc

qsys/
├── adc_reader.qsys
└── adc_reader.qip
```

## Building the Project

### Prerequisites
- Quartus Prime 18.0 or later
- DE10-Lite board

### Steps
1. Open Quartus Prime
2. Create new project for DE10-Lite (10M50DAF484C7G)
3. Add all VHDL files from `src/` directory
4. Set `adc_reader_top.vhd` as top-level entity
5. Run: `source constraints/de10_lite_pin_assignments.tcl`
6. Add `qsys/adc_reader.qip` and `constraints/adc_reader.sdc`
7. Compile and program to board

## Current Status

The system is mostly functional with some modules still being refined:

**Working modules:**
- ADC controller - reads all 5 channels correctly
- Timing controller - 5-second intervals working
- Channel selector - display switching works
- Display controller - voltage display functioning

**In progress:**
- Averaging unit - basic functionality working, calculations need debugging
- Calculation unit - advanced processing algorithms

**Planned:**
- ESP32 communication via UART
- Additional processing modes

## Known Issues

The averaging calculations sometimes produce inconsistent results. The sample accumulation logic is being debugged to ensure stable average values that match the expected sensor readings.

## Technical Details

- **System clock**: 50MHz
- **ADC clock**: 10MHz (from PLL)
- **ADC resolution**: 12-bit (0-4095)
- **Voltage range**: 0-5V
- **Update rate**: Continuous sampling, 5-second averaging

## Development Notes

This project evolved from a single-channel version that worked reliably. The expansion to 5 channels required significant changes to the ADC controller and the addition of averaging and selection logic.

The modular architecture makes it easy to test individual components and add new features. Each VHDL module has a specific responsibility and clear interfaces.

Future plans include integrating with an ESP32 for wireless data transmission and implementing more sophisticated signal processing algorithms.

## Testing

Basic functionality can be verified by:
1. Connecting a single flex sensor to A0
2. Enabling SW[0] and SW[1]
3. Bending the sensor and observing voltage changes on the display
4. Checking that LEDs indicate proper system operation

For multiple channels, connect sensors to different pins and use SW[2-5] to switch the display between channels.