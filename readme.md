# SDRAM Controller

基于 Intel Altera EP4CE10F17C8 设计

## sdram控制器

### 1. sdram_init

用于对 sdram 进行初始化操作；

参照硬件数据手册，sdram 芯片上电后须等待$ 200 \mu s$；随后进行预充电 (Precharge) 指令；预充电完成后需要进行 8 次自动刷新 (Auto-Refresh), 在此期间完成模式寄存器配置 (Mode Register Set)。
