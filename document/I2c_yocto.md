# 1. Tổng quan về giao thức I2C
I2C hay IIC (Inter – Integrated Circuit) là 1 giao thức giao tiếp nối tiếp đồng bộ được phát triển bởi Philips Semiconductors, sử dụng để truyền nhận dữ liệu giữa các IC với nhau chỉ sử dụng hai đường truyền tín hiệu.

I2C kết hợp các tính năng tốt nhất của SPI và UART. I2C có thể kết nối nhiều slave với một master duy nhất (như SPI) và có thể có nhiều master điều khiển một hoặc nhiều slave. Điều này thực sự cần thiết khi muốn có nhiều hơn một vi điều khiển ghi dữ liệu vào một thẻ nhớ duy nhất hoặc hiển thị văn bản trên một màn hình LCD.

![](./picture/i2c_yocto/i2c_protocol.png)

Giống như giao tiếp UART, I2C chỉ sử dụng hai dây để truyền dữ liệu giữa các thiết bị:
- SDA (Serial Data) - đường truyền cho master và slave để gửi và nhận dữ liệu.
- SCL (Serial Clock) - đường mang tín hiệu xung nhịp.

Các bit dữ liệu sẽ được truyền từng bit một dọc theo một đường duy nhất (SDA) theo các khoảng thời gian đều đặn được thiết lập bởi 1 tín hiệu đồng hồ (SCL).
Chi tiết cách thức hoạt động của I2C có thể tham khảo [tại đây](https://www.circuitbasics.com/basics-of-the-i2c-communication-protocol/)
# 2. I2C trong linux
![](./picture/i2c_yocto/i2c_protocol_linux.png)
Trong Linux, I2C được chia ra thành các thành phần chính sau:
- I2C Client Driver (I2C Device Driver): Là driver để điều khiển các thiết bị I2C.
- I2C core: Đây là 1 sub system trong Linux và nó sẽ giống nhau đối với tất cả các board chạy Linux ( Beagle bone, IMX, Raspberry pi, ...).
- I2C Platform Driver: Thông thường driver này sẽ do các nhà sản xuất SOC viết và tích hợp nó vào trong SDK. 

Ví dụ khi chúng ta viết một ứng dụng để giao tiếp với một màn hình OLED thì từ phía application chúng ta sẽ gọi các function để đọc ghi vào file. Sau đó, device driver nhận được thông tin sẽ giao tiếp với I2C core của Linux. Từ đây thì I2C core sẽ tương tác với I2C platform driver và driver này sẽ tác động trực tiếp đến các thanh ghi của hardware.

Bài viết hôm nay chúng ta sẽ tập trung vào phía Client Driver.

I2C protocol driver được dại diện trong kernel bằng *struct i2c_driver*. I2C client device được đại diện bằng *struct i2c_client*.
```
struct i2c_driver {
  unsigned int class;
  int (* attach_adapter) (struct i2c_adapter *);
  int (* probe) (struct i2c_client *, const struct i2c_device_id *);
  int (* remove) (struct i2c_client *);
  void (* shutdown) (struct i2c_client *);
  void (* alert) (struct i2c_client *, unsigned int data);
  int (* command) (struct i2c_client *client, unsigned int cmd, void *arg);
  struct device_driver driver;
  const struct i2c_device_id * id_table;
  int (* detect) (struct i2c_client *, struct i2c_board_info *);
  const unsigned short * address_list;
  struct list_head clients;
};  
```
- *probe*: callback gọi khi phát hiện thiết bị
- *remove*: callback gọi khi thiết bị đươc rút ra
- *shutdown*: callback gọi khi thiết bị shutdown
- *id_table*: Danh sách các thiết bị I2C được điều khiển bởi driver này

```
struct i2c_client {
  unsigned short flags;
  unsigned short addr;
  char name[I2C_NAME_SIZE];
  struct i2c_adapter * adapter;
  struct device dev;
  int irq;
  struct list_head detected;
#if IS_ENABLED(CONFIG_I2C_SLAVE)
  i2c_slave_cb_t slave_cb;
#endif
}; 
```
- *addr*: Địa chỉ của thiết bị trên bus I2C.
- *name*: Loại thiết bị.

Ở đây mình chỉ liệt kê ra các trường cơ bản trong struct. Nếu các bạn muốn tìm hiểu kĩ hơn có thể đọc [tại đây](https://www.linuxtv.org/downloads/v4l-dvb-internals/device-drivers/API-struct-i2c-client.html).

Để có thể gửi nhận dữ liệu trong I2C thì có hai API 
```
int i2c_master_send(struct i2c_client *client, const char *buf, int count);
int i2c_master_recv(struct i2c_client *client, char *buf, int count);
```
Trong đó:
- *client*: tham số được truyền vào hàm probe. Cái này thì kernel sẽ tự truyền.
- *buf*: là dữ liệu được gửi/nhận
- *count*: là số lượng dữ liệu gửi/nhận được tính theo byte 

# 3. Tổng quan SSD1306
![](https://assets.devlinux.vn/uploads/editor-images/2024/12/14/image_095c20683a.png)
SSD1306 có dộ phân giải 128x64 và được chia vào 8(0-7) pages. Mỗi page chứa 128(0-127) columns(segments). Và mỗi column chứa 8 bits.
![](https://assets.devlinux.vn/uploads/editor-images/2024/12/14/image_18ca34344a.png)
Giả sử muốn print kĩ tự A có kích thứớc 5x8 từ vị trí 0x0
- Đầu tiên, dịch chuyển cursor đến vị tri 0x0 s
- Sau đó, thực hiện ghi lần lượt 0x7C, 0x12, x011, 0x12, 0x7C
![](https://assets.devlinux.vn/uploads/editor-images/2024/12/14/image_26c13d7ebe.png)
Tham khảo các command khi làm việc với SSD1306 [tại đây](https://www.digikey.com/htmldatasheets/production/2047793/0/0/1/ssd1306.html#pf1c).

| **Command**    | **Command**             | **Description**                                                                                           |
|----------------|-------------------------|-----------------------------------------------------------------------------------------------------------|
| `0x00`        | COMMAND                 | This command is used to indicate the next data byte is acted as a command.                                |
| `0x40–0x7F`   | Display Start Line      | This command sets the Display Start Line register to determine the starting address of display RAM.       |
| `0xAE`        | Display OFF             | This command is used to turn OFF the OLED display panel.                                                  |
| `0xAF`        | Display ON              | This command is used to turn ON the OLED display panel.                                                   |
| `0x20`        | Memory Addressing Mode  | If horizontal address increment mode is enabled by command 20h, after finishing read/write one column data, it is incremented automatically to the next column address. |
| `0x2E`        | Deactivate Scroll       | This command deactivates the scroll.                                                                     |
| `0x2F`        | Activate Scroll         | This command activates the scroll if it is configured before.                                             |
| `0x21`        | Column Address          | This command is used to define the current read/write column address in graphic display data RAM.         |
| `0x22`        | Page Address            | This command is used to define the current read/write Line(Page as per data sheet) address in graphic display data RAM. |
| `0x81`        | Contrast Control        | This command sets the Contrast Setting of the display. The chip has 256 contrast steps from 00h to FFh. The segment output current increases as the contrast step value increases. |
| `0xA0`        | Segment Re-map          | This command sets the column address 0 is mapped to SEGO.                                                 |
| `0xA1`        | Segment Re-map          | This command sets the column address 127 is mapped to SEGO.                                               |
| `0xA6`       | Normal Display                                  | This command sets the display to normal mode. In the normal display, a RAM data of 1 indicates an "ON" pixel.       |
| `0xA7`       | Inverse Display                                 | This command sets the display to inverse mode. In the normal display, a RAM data of 0 indicates an "ON" pixel.      |
| `0xA8`       | Multiplex Ratio                                 | This command sets the display multiplex ratio.                                                                     |
| `0xC0/0xC8`  | COM Output Scan direction                       | 0xC0 - Normal mode (RESET) Scan from COM0 to COM[N-1]  <br> 0xC8 - Remapped mode. Scan from COM[N-1] to COM0 Where N is the Multiplex ratio. |
| `0xD3`       | Display Offset                                  | This command sets vertical shift by COM from 0d–63d.                                                                |
| `0xD5`       | Display Clock Divide Ratio/Oscillator Frequency | This command sets the display Clock Divide Ratio and Oscillator Frequency.                                         |
| `0x26/0x27`  | Continuous Horizontal Scroll                   | `0x26` - Right horizontal scroll <br> `0x27` - Left horizontal scroll                                              |
| `0x29/0x2A`  | Continuous Vertical and Horizontal Scroll       | `0x29` - Vertical and Right Horizontal Scroll <br> `0x2A` - Vertical and Left Horizontal Scroll                   |
# 4. Tích hợp driver SSD1306 vào kernel
## 4.1. Sử dụng devtool để modify kernel
```bash
~/yocto/sources/poky/build$ devtool modify virtual/kernel
```
## 4.2. Tạo thư mục chứa driver của ssd1306
Trong thư mục *drivers/* của source kernel chúng ta tạo 1 thư mục có tên *ssd1306*
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/drivers$ mkdir ssd1306
```
## 4.3.Viết driver
Trong thự mục *ssd1306* tạo tạo 3 file như dưới đây
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/drivers/ssd1306$ tree
.
├── Kconfig
├── Makefile
└── ssd1306.c
```
### 4.3.1. Source code

```
#include <linux/module.h>
#include <linux/init.h>
#include <linux/slab.h>
#include <linux/i2c.h>
#include <linux/delay.h>
#include <linux/kernel.h>
#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <asm/uaccess.h>

#define SSD1306_MAX_SEG         128
#define SSD1306_MAX_LINE        7
#define SSD1306_DEF_FONT_SIZE   5
#define MAX_BUFF 	        256

typedef struct ssd1306_i2c_module {
	struct i2c_client *client;
	dev_t ssd1306_dev_num;
	struct class *ssd1306_class;
	struct device *ssd1306_device_p;
	struct cdev ssd1306_cdev;
	uint8_t line_num;
	uint8_t cursor_position;
	uint8_t font_size;
} ssd1306_i2c_module_t;

static int ssd1306_open(struct inode *inodep,
      					  struct file *filep);
static int ssd1306_release(struct inode *inodep,
 							 struct file *filep);
static int ssd1306_write_ops(struct file *filep,
						   const char *buf,
		   				   size_t len, loff_t *offset);
static ssize_t ssd1306_read(struct file *filp,
							 char __user *buf,
							 size_t len,
							 loff_t *off);

char message[MAX_BUFF];
ssd1306_i2c_module_t* module_ssd1306 = NULL;
static struct file_operations fops = {
	.owner      = THIS_MODULE,
	.open = ssd1306_open,
	.release = ssd1306_release,
	.write = ssd1306_write_ops,
	.read = ssd1306_read
};

static const unsigned char ssd1306_font[][SSD1306_DEF_FONT_SIZE] = {
	{0x00, 0x00, 0x00, 0x00, 0x00}, // space
	{0x00, 0x00, 0x2f, 0x00, 0x00}, // !
	{0x00, 0x07, 0x00, 0x07, 0x00}, // "
	{0x14, 0x7f, 0x14, 0x7f, 0x14}, // #
	{0x24, 0x2a, 0x7f, 0x2a, 0x12}, // $
	{0x23, 0x13, 0x08, 0x64, 0x62}, // %
	{0x36, 0x49, 0x55, 0x22, 0x50}, // &
	{0x00, 0x05, 0x03, 0x00, 0x00}, // '
	{0x00, 0x1c, 0x22, 0x41, 0x00}, // (
	{0x00, 0x41, 0x22, 0x1c, 0x00}, // )
	{0x14, 0x08, 0x3E, 0x08, 0x14}, // *
	{0x08, 0x08, 0x3E, 0x08, 0x08}, // +
	{0x00, 0x00, 0xA0, 0x60, 0x00}, // ,
	{0x08, 0x08, 0x08, 0x08, 0x08}, // -
	{0x00, 0x60, 0x60, 0x00, 0x00}, // .
	{0x20, 0x10, 0x08, 0x04, 0x02}, // /
	{0x3E, 0x51, 0x49, 0x45, 0x3E}, // 0
	{0x00, 0x42, 0x7F, 0x40, 0x00}, // 1
	{0x42, 0x61, 0x51, 0x49, 0x46}, // 2
	{0x21, 0x41, 0x45, 0x4B, 0x31}, // 3
	{0x18, 0x14, 0x12, 0x7F, 0x10}, // 4
	{0x27, 0x45, 0x45, 0x45, 0x39}, // 5
	{0x3C, 0x4A, 0x49, 0x49, 0x30}, // 6
	{0x01, 0x71, 0x09, 0x05, 0x03}, // 7
	{0x36, 0x49, 0x49, 0x49, 0x36}, // 8
	{0x06, 0x49, 0x49, 0x29, 0x1E}, // 9
	{0x00, 0x36, 0x36, 0x00, 0x00}, // :
	{0x00, 0x56, 0x36, 0x00, 0x00}, // ;
	{0x08, 0x14, 0x22, 0x41, 0x00}, // <
	{0x14, 0x14, 0x14, 0x14, 0x14}, // =
	{0x00, 0x41, 0x22, 0x14, 0x08}, // >
	{0x02, 0x01, 0x51, 0x09, 0x06}, // ?
	{0x32, 0x49, 0x59, 0x51, 0x3E}, // @
	{0x7C, 0x12, 0x11, 0x12, 0x7C}, // A
	{0x7F, 0x49, 0x49, 0x49, 0x36}, // B
	{0x3E, 0x41, 0x41, 0x41, 0x22}, // C
	{0x7F, 0x41, 0x41, 0x22, 0x1C}, // D
	{0x7F, 0x49, 0x49, 0x49, 0x41}, // E
	{0x7F, 0x09, 0x09, 0x09, 0x01}, // F
	{0x3E, 0x41, 0x49, 0x49, 0x7A}, // G
	{0x7F, 0x08, 0x08, 0x08, 0x7F}, // H
	{0x00, 0x41, 0x7F, 0x41, 0x00}, // I
	{0x20, 0x40, 0x41, 0x3F, 0x01}, // J
	{0x7F, 0x08, 0x14, 0x22, 0x41}, // K
	{0x7F, 0x40, 0x40, 0x40, 0x40}, // L
	{0x7F, 0x02, 0x0C, 0x02, 0x7F}, // M
	{0x7F, 0x04, 0x08, 0x10, 0x7F}, // N
	{0x3E, 0x41, 0x41, 0x41, 0x3E}, // O
	{0x7F, 0x09, 0x09, 0x09, 0x06}, // P
	{0x3E, 0x41, 0x51, 0x21, 0x5E}, // Q
	{0x7F, 0x09, 0x19, 0x29, 0x46}, // R
	{0x46, 0x49, 0x49, 0x49, 0x31}, // S
	{0x01, 0x01, 0x7F, 0x01, 0x01}, // T
	{0x3F, 0x40, 0x40, 0x40, 0x3F}, // U
	{0x1F, 0x20, 0x40, 0x20, 0x1F}, // V
	{0x3F, 0x40, 0x38, 0x40, 0x3F}, // W
	{0x63, 0x14, 0x08, 0x14, 0x63}, // X
	{0x07, 0x08, 0x70, 0x08, 0x07}, // Y
	{0x61, 0x51, 0x49, 0x45, 0x43}, // Z
	{0x00, 0x7F, 0x41, 0x41, 0x00}, // [
	{0x55, 0xAA, 0x55, 0xAA, 0x55}, // Backslash (Checker pattern)
	{0x00, 0x41, 0x41, 0x7F, 0x00}, // ]
	{0x04, 0x02, 0x01, 0x02, 0x04}, // ^
	{0x40, 0x40, 0x40, 0x40, 0x40}, // _
	{0x00, 0x03, 0x05, 0x00, 0x00}, // `
	{0x20, 0x54, 0x54, 0x54, 0x78}, // a
	{0x7F, 0x48, 0x44, 0x44, 0x38}, // b
	{0x38, 0x44, 0x44, 0x44, 0x20}, // c
	{0x38, 0x44, 0x44, 0x48, 0x7F}, // d
	{0x38, 0x54, 0x54, 0x54, 0x18}, // e
	{0x08, 0x7E, 0x09, 0x01, 0x02}, // f
	{0x18, 0xA4, 0xA4, 0xA4, 0x7C}, // g
	{0x7F, 0x08, 0x04, 0x04, 0x78}, // h
	{0x00, 0x44, 0x7D, 0x40, 0x00}, // i
	{0x40, 0x80, 0x84, 0x7D, 0x00}, // j
	{0x7F, 0x10, 0x28, 0x44, 0x00}, // k
	{0x00, 0x41, 0x7F, 0x40, 0x00}, // l
	{0x7C, 0x04, 0x18, 0x04, 0x78}, // m
	{0x7C, 0x08, 0x04, 0x04, 0x78}, // n
	{0x38, 0x44, 0x44, 0x44, 0x38}, // o
	{0xFC, 0x24, 0x24, 0x24, 0x18}, // p
	{0x18, 0x24, 0x24, 0x18, 0xFC}, // q
	{0x7C, 0x08, 0x04, 0x04, 0x08}, // r
	{0x48, 0x54, 0x54, 0x54, 0x20}, // s
	{0x04, 0x3F, 0x44, 0x40, 0x20}, // t
	{0x3C, 0x40, 0x40, 0x20, 0x7C}, // u
	{0x1C, 0x20, 0x40, 0x20, 0x1C}, // v
	{0x3C, 0x40, 0x30, 0x40, 0x3C}, // w
	{0x44, 0x28, 0x10, 0x28, 0x44}, // x
	{0x1C, 0xA0, 0xA0, 0xA0, 0x7C}, // y
	{0x44, 0x64, 0x54, 0x4C, 0x44}, // z
	{0x00, 0x10, 0x7C, 0x82, 0x00}, // {
	{0x00, 0x00, 0xFF, 0x00, 0x00}, // |
	{0x00, 0x82, 0x7C, 0x10, 0x00}, // }
	{0x00, 0x06, 0x09, 0x09, 0x06}  // ~ (Degrees)
};

static int ssd1306_i2c_write(ssd1306_i2c_module_t *module, unsigned char *buf, unsigned int len)
{
    return i2c_master_send(module->client, buf, len);
}

static int ssd1306_i2c_read(ssd1306_i2c_module_t *module, unsigned char *out_buf, unsigned int len)
{
    return i2c_master_recv(module->client, out_buf, len);
}

static void ssd1306_write(ssd1306_i2c_module_t *module, bool is_cmd, unsigned char data)
{
	unsigned char buf[2] = {0};

	if (is_cmd == true) {
		buf[0] = 0x00;
	} else {
		buf[0] = 0x40;
	}

	buf[1] = data;
	ssd1306_i2c_write(module, buf, 2);
}

static void ssd1306_set_cursor(ssd1306_i2c_module_t *module, uint8_t line_num, uint8_t cursor_position)
{
	if ((line_num <= SSD1306_MAX_LINE) && (cursor_position < SSD1306_MAX_SEG)) {
		module->line_num = line_num;                       // Save the specified line number
		module->cursor_position = cursor_position; // Save the specified cursor position
		ssd1306_write(module, true, 0x21);                                 // cmd for the column start and end address
		ssd1306_write(module, true, cursor_position);      // column start addr
		ssd1306_write(module, true, SSD1306_MAX_SEG - 1);  // column end addr
		ssd1306_write(module, true, 0x22);                                 // cmd for the page start and end address
		ssd1306_write(module, true, line_num);                     // page start addr
		ssd1306_write(module, true, SSD1306_MAX_LINE);     // page end addr
	}
}

static void ssd1306_goto_next_line(ssd1306_i2c_module_t *module)
{
	module->line_num++;
	module->line_num = (module->line_num & SSD1306_MAX_LINE);
	ssd1306_set_cursor(module, module->line_num, 0);
}

static void ssd1306_print_char(ssd1306_i2c_module_t *module, unsigned char c)
{
	uint8_t data_byte;
	uint8_t temp = 0;

	if (((module->cursor_position + module->font_size) >= SSD1306_MAX_SEG) || (c == '\n'))
			ssd1306_goto_next_line(module);

	if (c != '\n') {
		c -= 0x20;
		do {
			data_byte = ssd1306_font[c][temp];
			ssd1306_write(module, false, data_byte);
			module->cursor_position++;

			temp++;
		} while (temp < module->font_size);

		ssd1306_write(module, false, 0x00);
		module->cursor_position++;
	}
}

static void ssd1306_set_brightness(ssd1306_i2c_module_t *module, uint8_t brightness)
{
	ssd1306_write(module, true, 0x81);
	ssd1306_write(module, true, brightness);
}

static void ssd1306_clear(ssd1306_i2c_module_t *module)
{
	unsigned int total = 128 * 8;
	int i;

	for (i = 0; i < total; i++) {
		ssd1306_write(module, false, 0);
	}
}

static void ssd1306_print_string(ssd1306_i2c_module_t *module, unsigned char *str)
{
	ssd1306_clear(module);
	ssd1306_set_cursor(module, 0, 0);
	while (*str) {
		ssd1306_print_char(module, *str++);
	}
}

static int ssd1306_display_init(ssd1306_i2c_module_t *module)
{
	msleep(100);
	ssd1306_write(module, true, 0xAE); // Entire Display OFF
	ssd1306_write(module, true, 0xD5); // Set Display Clock Divide Ratio and Oscillator Frequency
	ssd1306_write(module, true, 0x80); // Default Setting for Display Clock Divide Ratio and Oscillator Frequency that is recommended
	ssd1306_write(module, true, 0xA8); // Set Multiplex Ratio
	ssd1306_write(module, true, 0x3F); // 64 COM lines
	ssd1306_write(module, true, 0xD3); // Set display offset
	ssd1306_write(module, true, 0x00); // 0 offset
	ssd1306_write(module, true, 0x40); // Set first line as the start line of the display
	ssd1306_write(module, true, 0x8D); // Charge pump
	ssd1306_write(module, true, 0x14); // Enable charge dump during display on
	ssd1306_write(module, true, 0x20); // Set memory addressing mode
	ssd1306_write(module, true, 0x00); // Horizontal addressing mode
	ssd1306_write(module, true, 0xA1); // Set segment remap with column address 127 mapped to segment 0
	ssd1306_write(module, true, 0xC8); // Set com output scan direction, scan from com63 to com 0
	ssd1306_write(module, true, 0xDA); // Set com pins hardware configuration
	ssd1306_write(module, true, 0x12); // Alternative com pin configuration, disable com left/right remap
	ssd1306_write(module, true, 0x81); // Set contrast control
	ssd1306_write(module, true, 0x80); // Set Contrast to 128
	ssd1306_write(module, true, 0xD9); // Set pre-charge period
	ssd1306_write(module, true, 0xF1); // Phase 1 period of 15 DCLK, Phase 2 period of 1 DCLK
	ssd1306_write(module, true, 0xDB); // Set Vcomh deselect level
	ssd1306_write(module, true, 0x20); // Vcomh deselect level ~ 0.77 Vcc
	ssd1306_write(module, true, 0xA4); // Entire display ON, resume to RAM content display
	ssd1306_write(module, true, 0xA6); // Set Display in Normal Mode, 1 = ON, 0 = OFF
	ssd1306_write(module, true, 0x2E); // Deactivate scroll
	ssd1306_write(module, true, 0xAF); // Display ON in normal mode
	ssd1306_clear(module);

	return 0;
}

/*
 * Turn on LCD
 */
static int ssd1306_open(struct inode *inodep, struct file *filep)
{
	pr_info("Go to %s, %d\n", __func__, __LINE__);
	return 0;
}

/*
 * Turn off LCD
 */
static int ssd1306_release(struct inode *inodep, struct file *filep)
{
	pr_info("Go to %s, %d\n", __func__, __LINE__);

	filep->private_data = NULL;
	return 0;
}

/*
 * Display Text to LCD
 */
static int ssd1306_write_ops(struct file *filep, const char *buf,
						     size_t len, loff_t *offset)
{
	int ret;

	pr_info("Go to %s, %d\n", __func__, __LINE__);
	memset(message, 0x0, sizeof(message));
    if (len > sizeof(message) - 1) {
        pr_info("Input data too large, truncating...\n");
        len = sizeof(message) - 1;
    }

    ret = copy_from_user(message, buf, len);
	if (ret) {
		pr_err("can not copy from user\n");
		return -ENOMSG;
	}
	pr_info("\nUser send: \"%s\"\n", message);
	ssd1306_clear(module_ssd1306);
	ssd1306_print_string(module_ssd1306, message);

	return len;
}

/*
 * Read Text from LCD
 */
static ssize_t ssd1306_read(struct file *filp, char __user *buf, size_t len, loff_t *off)
{
    ssize_t bytes_to_read = min(len, (size_t)(MAX_BUFF - *off));

    if (bytes_to_read <= 0) {
        pr_info("Data Read: End of file\n");
        return 0; // End of file
    }

    if (copy_to_user(buf, message + *off, bytes_to_read)) {
        pr_err("Data Read: Err!\n");
        return -EFAULT;
    }

    *off += bytes_to_read;
    pr_info("Data Read: Done!\n");
    return bytes_to_read;
}

static int ssd1306_create_device_file(ssd1306_i2c_module_t *module)
{
	int res = 0;
	pr_info("Go to : %s, %d\n", __func__, __LINE__);
	/* Register range device numbers for number of LCD devices */
	res = alloc_chrdev_region(&(module->ssd1306_dev_num), 0, 1, "ssd1306_device");
	pr_info("Major = %d Minor = %d\n", MAJOR(module->ssd1306_dev_num), MINOR(module->ssd1306_dev_num));
	if (res < 0) {
		pr_info("Error occur, can not register major number\n");
		goto alloc_dev_failed;
	}

	/* Create the class for all of LCD Devices */
	module->ssd1306_class = class_create(THIS_MODULE, "ssd1306_class");
	if (module->ssd1306_class  == NULL) {
		pr_info("Error occur, can not create class device\n");
		goto create_class_failed;
	}

	/* Create Device File In User Space */
	module->ssd1306_device_p = device_create(module->ssd1306_class, NULL, module->ssd1306_dev_num,
							   NULL, "ssd1306"); /* /dev/ssd1306*/
	if (module->ssd1306_device_p == NULL) {
		pr_info("Error occur, can not register major number\n");
		goto device_create_fail;
	}

	/* Register operations of device */
	cdev_init(&module->ssd1306_cdev, &fops);
	(module->ssd1306_cdev).owner = THIS_MODULE;
	(module->ssd1306_cdev).dev = module->ssd1306_dev_num;

	res = cdev_add(&module->ssd1306_cdev, module->ssd1306_dev_num, 1);
	if (res) {
		pr_info("error occur when add properties for struct cdev\n");
		goto cdev_add_fail;
	}
	pr_info("Go out : %s, %d \n", __func__, res);
	return res;
cdev_add_fail:
	device_destroy(module->ssd1306_class, module->ssd1306_dev_num);
device_create_fail:
    class_destroy(module->ssd1306_class);
create_class_failed:
	unregister_chrdev_region(module->ssd1306_dev_num, 1);
alloc_dev_failed:
	return res;
}

static int ssd1306_i2c_probe(struct i2c_client *client)
{
	ssd1306_i2c_module_t *module;
	pr_info("Go to I2c probe: %s, %d\n", __func__, __LINE__);
	module = kmalloc(sizeof(*module), GFP_KERNEL);
	if (!module) {
		pr_err("kmalloc failed\n");
		return -1;
	}

	module->client = client;
	module->line_num = 0;
	module->cursor_position = 0;
	module->font_size = SSD1306_DEF_FONT_SIZE;
	i2c_set_clientdata(client, module);
	ssd1306_display_init(module);
	ssd1306_set_cursor(module, 0, 0);
	if (ssd1306_create_device_file(module) != 0) {
		kfree(module);
		pr_err("Fail to create device file.\n");
		return -1;
	}

	module_ssd1306 = module;
	pr_info("Go out I2c probe: %s, %d\n", __func__, __LINE__);
	return 0;
}

static int ssd1306_i2c_remove(struct i2c_client *client)
{
	ssd1306_i2c_module_t *module = i2c_get_clientdata(client);
	ssd1306_print_string(module, "End!!!");
	msleep(1000);
	ssd1306_clear(module);
	ssd1306_write(module, true, 0xAE); // Entire Display OFF
    cdev_del(&module->ssd1306_cdev);
	device_destroy(module->ssd1306_class, module->ssd1306_dev_num);
    class_destroy(module->ssd1306_class);
    unregister_chrdev_region(module->ssd1306_dev_num, 1);
	kfree(module);
	pr_info("Devlinux_end: %s, %d\n", __func__, __LINE__);
	return 0;
}

static const struct of_device_id ssd1306_of_match_id[] = {
	{ .compatible = "solomon,ssd1306", 0 },
	{ }
};

MODULE_DEVICE_TABLE(of, ssd1306_of_match_id);

static struct i2c_driver ssd1306_i2c_driver = {
	.driver = {
		.name = "ssd1306",
		.owner = THIS_MODULE,
		.of_match_table = ssd1306_of_match_id,
	},
	.probe_new = ssd1306_i2c_probe,
	.remove = ssd1306_i2c_remove,
};

static int __init func_init(void)
{
	/* Register spi_driver - protocol driver */
	return i2c_register_driver(THIS_MODULE, &ssd1306_i2c_driver);
}

static void __exit func_exit(void)
{
	return i2c_del_driver(&ssd1306_i2c_driver);
}

module_init(func_init);
module_exit(func_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("DevLinux");
MODULE_DESCRIPTION("SSD1306");
```

Trong source code
- Chúng ta đã wrap các thông tin liên quan đên ssd1306 vào một struct 
```
struct ssd1306_i2c_module {
        struct i2c_client *client;     /* struct i2c_client tương ứng với ssd1306*/
        uint8_t line_num;                /* cho biết line hiện tại của màn ssd1306 */
        uint8_t cursor_position;    /* cho biết vị trí hiện tại trên màn */
        uint8_t font_size;               /* kich cỡ font */
};
```
- Hàm *ssd1306_i2c_probe* sẽ được gọi trường compatible của driver và device tree giống nhau.
	 - Trong hàm probe chúng ta sẽ khởi tạo các cấu hình cần thiết cho ssd1306 thông qua hàm *ssd1306_display_init*
	 - Sau đó, gửi 1 string "Hello\nworld\n" để hiển thị lên màn hình OLED
- Hàm *ssd1306_i2c_remove* sẽ có nhiệm vụ là remove những gì đã cấp phát khi hàm probe được gọi.
- *struct of_device_id* để cho biết những thiết bị nào được support bởi driver này.
- Macro *MODULE_DEVICE_TABLE* được sử dụng để khai báo và đăng ký thông tin về các thiết bị mà driver hỗ trợ. Nó giúp kernel xây dựng mối quan hệ giữa driver và các thiết bị phần cứng tương ứng.
- struct i2c_driver để khai báo các function probe và remove của driver cũng như là tên driver và list thiêt bị được driver support. Lưu ý là hiện nay trường *probe* trong struct này đã được thay đổi thành *probe_new* và prototype của nó cũng thay đổi là chỉ cần nhận vào 1 đối số *i2c_client*.
- *module_i2c_driver* được sử dụng để đăng ki và khởi tạo một i2c driver với kernel .
### 4.3.2. Makefile
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/drivers/ssd1306$ cat Makefile
obj-$(CONFIG_SSD1306) += ssd1306.o
```
### 4.3.1. Kconfig
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/drivers/ssd1306$ cat Kconfig
config SSD1306
    tristate "Module I2C SSD1306"
    default y
    help
      This is driver for module I2C SSD1306.
```

## 4.4. Sửa file Kconfig và Makefile ở drivers/
Trong thư mục drivers/ thêm dòng sau vào file Kconfig
```bash
source "drivers/ssd1306/Kconfig"
```
Thêm dòng sau vào file Makefile ( built-in)
```bash
obj-$(CONFIG_SSD1306) += ssd1306/
```
Sau khi sửa, chúng ta có thể build lại file .config bằng lệnh:
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/drivers$ bitbake linux-raspberrypi -c menuconfig
```
Một menuconfig sẽ hiện ra để chúng ta có thể cấu hình thay đổi build-in hay build module cho driver.
Sau đó, lưu lại và chạy lệnh sau để lưu lại file defconfig
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/drivers$ bitbake linux-raspberrypi -c savedefconfig
```
## 4.5. Khai báo ssd1306 trong device tree
Sửa file *~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/arch/arm/boot/dts/bcm2708-rpi-zero-w.dts*
```
&i2c1 {
        pinctrl-names = "default";
        pinctrl-0 = <&i2c1_pins>;
        clock-frequency = <100000>;
    status = "okay";
    ssd1306: oled@3c {  /* Địa chỉ I2C của SSD1306 */
        compatible = "ssd1306";
        reg = <0x3c>;
        width = <128>;
        height = <64>;
        status = "okay";
    };
};
```
Thêm một node để cấu hình cho SSD1306 trong node i2c1. Lưu ý trường compatibale phải trùng với driver.
## 4.6. Build lại kernel và image
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/arch/arm/boot/dts$ devtool build linux-raspberrypi
```
```bash
~/yocto/sources/poky/build/workspace/sources/linux-raspberrypi/arch/arm/boot/dts$ bitbake core-image-minimal
```

Sau khi build xong, copy flash image nằm vào thẻ nhớ
# 5. Kết quả
Sau khi khởi động thiết bị xong check log thấy hàm probe đã được gọi
![](./picture/i2c_yocto/result_i2c.png)

