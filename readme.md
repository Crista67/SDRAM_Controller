# SDRAM Controller

基于 Intel Altera EP4CE10F17C8 设计

## sdram控制器

### 1. sdram_init

用于对 sdram 进行初始化操作；

参照硬件数据手册，sdram 芯片上电后须等待 $ 200 \mu s$；随后进行预充电 (Precharge) 指令；预充电完成后需要进行 8 次自动刷新 (Auto-Refresh), 在此期间完成模式寄存器配置 (Mode Register Set).

### 2. sdram_aref

用于 sdram 的定时自动刷新；

芯片每个 bank 共有 8192 行，按照要求需要每 64ms 需要刷新 8192 次；因此刷新周期不得大于 $7.8125 \mu s$；

考虑到实际可能存在的延时，为保证刷新能够正常工作，设置刷新周期为 $7.5\mu s$, 即 750 个时钟周期；

刷新操作每 $7.5 \mu s$ 进行一次，每次须先进行预充电 (Precharge) 操作，随后进行两次自动刷新 (Auto-Refresh) 操作；

刷新操作在初始化完成后开始计时，并在计时达到最大值后向仲裁模块发出请求，收到仲裁模块的使能信号后开始刷新操作.
