#include <linux/netdevice.h>
#include <linux/ethtool.h>
#include <linux/init.h> 
#include <linux/kernel.h> 
#include <linux/module.h> 
#include <linux/moduleparam.h> 
#include <linux/fs.h> 
#include <linux/miscdevice.h> 
#include <linux/string.h> 
#include <linux/slab.h> 
#include <linux/sched.h> 
#include <linux/uaccess.h>
#include <linux/pci.h>
#include <xpmon_be.h>
#include "xdebug.h"
#include "xbasic_types.h"
#include "xstatus.h"
#include "../xdma/xdma.h"
#include "../xdma/xdma_hw.h"
#include "../xdma/xdma_bdring.h"
#include "../xdma/xdma_user.h"
MODULE_LICENSE("GPL");
MODULE_AUTHOR("yifan"); 
MODULE_DESCRIPTION("yifan");



int timer_interval;
int thre_high_rx;
int thre_low_rx;
int thre_high_tx;
int thre_safe;
int aggre;
int ncap_enable;

static int __init dui_init(void){

	struct pci_dev *dev = NULL;

	read_lock(&dev_base_lock);
	dev = pci_get_device(0x10EE, PCI_ANY_ID, dev);

    read_unlock(&dev_base_lock);

	if(dev == NULL){
		printk(KERN_INFO "yifan:cuo\n");
		return;
	}

	struct privData *lp;
	lp = pci_get_drvdata(dev);
	u64 base;
	base = (lp->barInfo[0].baseVaddr);

	Dma_mWriteReg(base, REG_TIMER_INTERVAL ,timer_interva );
	Dma_mWriteReg(base,REG_THRESHOLD_HIGH_RX , thre_high_rx);
	Dma_mWriteReg(base,REG_THRESHOLD_HIGH_TX ,thre_high_tx );
	Dma_mWriteReg(base,REG_THRESHOLD_LOW_RX , thre_low_rx);
	Dma_mWriteReg(base,REG_THRESHOLD_SAFEGUARD ,thre_safe );
	Dma_mWriteReg(base,REG_AGGRESSIVE_MODE ,aggre );
	Dma_mWriteReg(base,REG_NCAP_ENABLE , ncap_enable);


	return 0;
}

static void __exit dui_exit(void){
	return;
}

module_init(dui_init);
module_exit(dui_exit);

module_param(timer_interva ,int, S_IRUGO);
module_param(thre_high_rx ,int, S_IRUGO);
module_param(thre_low_rx ,int, S_IRUGO);
module_param(thre_high_tx ,int, S_IRUGO);
module_param(thre_safe ,int, S_IRUGO);
module_param(aggre ,int, S_IRUGO);
module_param(ncap_enable ,int, S_IRUGO);