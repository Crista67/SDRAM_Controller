# SDRAM Controller

Designed based on Intel Altera EP4CE10F17C8, with the controlled chip being the Winbond W9825G6KH-6 SDR SDRAM chip.

## 1. Internal Modules of the SDRAM Controller

### (1) sdram_init

Used for initializing the SDRAM.

According to the hardware datasheet, after powering up the SDRAM chip, it needs to wait for $200 \mu s$; then perform the Precharge command; after precharge, 8 Auto-Refresh operations need to be performed, during which the Mode Register Set is configured.

### (2) sdram_aref

Used for periodic automatic refresh of the SDRAM.

Each bank of the chip has 8192 rows, and it needs to be refreshed 8192 times every $64ms$; therefore, the refresh cycle must not exceed $7.8125 \mu s$.

Considering possible delays in practice, to ensure proper refresh operation, the refresh cycle is set to $7.5 \mu s$, which is 750 clock cycles.

The refresh operation is performed once every $7.5 \mu s$. Each time, a precharge operation is performed first, followed by two Auto-Refresh operations.

The refresh operation starts timing after initialization is completed, and requests are sent to the arbitration module when the timing reaches the maximum value. After receiving the enable signal from the arbitration module, the refresh operation begins.

### (3) sdram_write

Used to write data into the SDRAM.

Signals passed to the module include write address, data to be written, and burst length.

The write burst is set to page burst, but the burst length can also be set to end the burst early if the data does not fill the entire page.

The write address is 24 bits, including 2 bits for the bank address, 13 bits for the row address, and 9 bits for the column address.

### (4) sdram_read

Used to read data from the SDRAM.

Signals passed include read address, read enable, and burst length.

Unlike the write module, the read enable signal needs to be manually provided, while the write enable signal is issued by the upper module.

The read module is also set to page burst mode, with burst length and read address settings similar to the write module.

### (5) sdram_arbit

Arranges the timing and priority of initialization, refresh, read, and write modules.

Upon controller startup, initialization is automatically performed, and after the initialization completion signal is sent out, the arbitration module starts working.

According to module settings, the refresh module has the highest priority. Therefore, when request signals are simultaneously received, the refresh module is entered first for refresh operations.

The write module has the second priority, and the read module has the third priority.

When a module is working, if request signals from other modules are received, the working module will not exit but keep the request signal high until the current module exits, then enter the requesting module. Conflicts at this time still follow the priority arrangement mentioned above.

### (6) sdram_ctrl

SDRAM control module, the top module of arbitration, initialization, read, write, and automatic refresh modules.

### (7) fifo_ctrl

FIFO read/write control module, used for buffering data before writing to SDRAM or after reading from SDRAM, ensuring data transfer across clock domains and waiting.

### (8) sdram_top

Top module of the SDRAM controller, connecting the FIFO read/write control and SDRAM control modules.

## 2. External Modules of the SDRAM Controller

### (1) clk_gen

PLL IP core called from Quartus, used to generate clock signals of different frequencies and phases for use by various modules.

### (2) uart_rx and uart_tx

Designed based on the RS232 protocol, used for communication between the SDRAM controller and the host computer.

The UART baud rate is set to 9600, with 8-bit data width and no parity bit.

### (3) fifo_read

Uses FIFO to buffer data read from SDRAM for transmission to the external device via UART.

### (4) uart_sdram

Top module of the project, implementing instantiation and connection of all project modules.
