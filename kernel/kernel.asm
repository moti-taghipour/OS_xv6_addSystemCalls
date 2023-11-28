
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a5010113          	addi	sp,sp,-1456 # 80008a50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8be70713          	addi	a4,a4,-1858 # 80008910 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	dec78793          	addi	a5,a5,-532 # 80005e50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc22f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f5278793          	addi	a5,a5,-174 # 80001000 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
                }
            }
        }

int
consolewrite(int user_src, uint64 src, int n) {
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++) {
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	50e080e7          	jalr	1294(ra) # 8000263a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
            break;
        uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00001097          	auipc	ra,0x1
    80000140:	908080e7          	jalr	-1784(ra) # 80000a44 <uartputc>
    for (i = 0; i < n; i++) {
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++) {
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n) {
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000186:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	bcc080e7          	jalr	-1076(ra) # 80000d5e <acquire>
    while (n > 0) {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w) {
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
            if (killed(myproc())) {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D')) {  // end-of-file
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n') {
    800001ae:	4ca9                	li	s9,10
    while (n > 0) {
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w) {
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc())) {
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	974080e7          	jalr	-1676(ra) # 80001b34 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2bc080e7          	jalr	700(ra) # 80002484 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	006080e7          	jalr	6(ra) # 800021dc <sleep>
        while (cons.r == cons.w) {
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
        if (c == C('D')) {  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	3d2080e7          	jalr	978(ra) # 800025e4 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n') {
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	be4080e7          	jalr	-1052(ra) # 80000e12 <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bce080e7          	jalr	-1074(ra) # 80000e12 <release>
                return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
            if (n < target) {
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
void consputc(int c) {
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE) {
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
        uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	6e6080e7          	jalr	1766(ra) # 80000972 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	6d4080e7          	jalr	1748(ra) # 80000972 <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	6c8080e7          	jalr	1736(ra) # 80000972 <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	6be080e7          	jalr	1726(ra) # 80000972 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <addCommand>:
void addCommand() {
    800002be:	7171                	addi	sp,sp,-176
    800002c0:	f506                	sd	ra,168(sp)
    800002c2:	f122                	sd	s0,160(sp)
    800002c4:	ed26                	sd	s1,152(sp)
    800002c6:	1900                	addi	s0,sp,176
    unsigned int ind = cons.w;
    800002c8:	00011697          	auipc	a3,0x11
    800002cc:	8246a683          	lw	a3,-2012(a3) # 80010aec <cons+0x9c>
    while (in_size + 1 < INPUT_BUF) {
    800002d0:	f6040513          	addi	a0,s0,-160
    800002d4:	fdf40593          	addi	a1,s0,-33
    unsigned int ind = cons.w;
    800002d8:	872a                	mv	a4,a0
    800002da:	9e89                	subw	a3,a3,a0
        command[in_size] = cons.buf[ind];
    800002dc:	00010617          	auipc	a2,0x10
    800002e0:	77460613          	addi	a2,a2,1908 # 80010a50 <cons>
    800002e4:	00d707bb          	addw	a5,a4,a3
    800002e8:	1782                	slli	a5,a5,0x20
    800002ea:	9381                	srli	a5,a5,0x20
    800002ec:	97b2                	add	a5,a5,a2
    800002ee:	0187c783          	lbu	a5,24(a5) # 10018 <_entry-0x7ffeffe8>
    800002f2:	00f70023          	sb	a5,0(a4)
    while (in_size + 1 < INPUT_BUF) {
    800002f6:	0705                	addi	a4,a4,1
    800002f8:	feb716e3          	bne	a4,a1,800002e4 <addCommand+0x26>
        char hiscom[7] = {'h', 'i', 's', 't', 'o', 'r', 'y'};
    800002fc:	747377b7          	lui	a5,0x74737
    80000300:	96878793          	addi	a5,a5,-1688 # 74736968 <_entry-0xb8c9698>
    80000304:	f4f42c23          	sw	a5,-168(s0)
    80000308:	679d                	lui	a5,0x7
    8000030a:	26f78793          	addi	a5,a5,623 # 726f <_entry-0x7fff8d91>
    8000030e:	f4f41e23          	sh	a5,-164(s0)
    80000312:	07900793          	li	a5,121
    80000316:	f4f40f23          	sb	a5,-162(s0)
         for (int i = 0; i < 7; i++) {
    8000031a:	f5840793          	addi	a5,s0,-168
    8000031e:	00750613          	addi	a2,a0,7
        int check = 0;
    80000322:	4581                	li	a1,0
    80000324:	a029                	j	8000032e <addCommand+0x70>
         for (int i = 0; i < 7; i++) {
    80000326:	0505                	addi	a0,a0,1
    80000328:	0785                	addi	a5,a5,1
    8000032a:	00c50a63          	beq	a0,a2,8000033e <addCommand+0x80>
             if (command[i] == hiscom[i]) {
    8000032e:	00054683          	lbu	a3,0(a0)
    80000332:	0007c703          	lbu	a4,0(a5)
    80000336:	fee698e3          	bne	a3,a4,80000326 <addCommand+0x68>
                 check++;
    8000033a:	2585                	addiw	a1,a1,1
    8000033c:	b7ed                	j	80000326 <addCommand+0x68>
                if (command[0] && check != 7) {
    8000033e:	f6044783          	lbu	a5,-160(s0)
    80000342:	c781                	beqz	a5,8000034a <addCommand+0x8c>
    80000344:	479d                	li	a5,7
    80000346:	00f59763          	bne	a1,a5,80000354 <addCommand+0x96>
        }
    8000034a:	70aa                	ld	ra,168(sp)
    8000034c:	740a                	ld	s0,160(sp)
    8000034e:	64ea                	ld	s1,152(sp)
    80000350:	614d                	addi	sp,sp,176
    80000352:	8082                	ret
                    safestrcpy(his.BufferArr[his.lastCommandIndex], command, INPUT_BUF);
    80000354:	00011497          	auipc	s1,0x11
    80000358:	7a448493          	addi	s1,s1,1956 # 80011af8 <proc+0x308>
    8000035c:	8404e783          	lwu	a5,-1984(s1)
    80000360:	079e                	slli	a5,a5,0x7
    80000362:	08000613          	li	a2,128
    80000366:	f6040593          	addi	a1,s0,-160
    8000036a:	00010517          	auipc	a0,0x10
    8000036e:	78e50513          	addi	a0,a0,1934 # 80010af8 <his>
    80000372:	953e                	add	a0,a0,a5
    80000374:	00001097          	auipc	ra,0x1
    80000378:	c30080e7          	jalr	-976(ra) # 80000fa4 <safestrcpy>
                    his.lastCommandIndex = (his.lastCommandIndex + 1) % MAX_HISTORY;
    8000037c:	8404a783          	lw	a5,-1984(s1)
    80000380:	2785                	addiw	a5,a5,1
    80000382:	8bbd                	andi	a5,a5,15
    80000384:	84f4a023          	sw	a5,-1984(s1)
        }
    80000388:	b7c9                	j	8000034a <addCommand+0x8c>

000000008000038a <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c) {
    8000038a:	1101                	addi	sp,sp,-32
    8000038c:	ec06                	sd	ra,24(sp)
    8000038e:	e822                	sd	s0,16(sp)
    80000390:	e426                	sd	s1,8(sp)
    80000392:	e04a                	sd	s2,0(sp)
    80000394:	1000                	addi	s0,sp,32
    80000396:	84aa                	mv	s1,a0
    // int x = 0;
    acquire(&cons.lock);
    80000398:	00010517          	auipc	a0,0x10
    8000039c:	6b850513          	addi	a0,a0,1720 # 80010a50 <cons>
    800003a0:	00001097          	auipc	ra,0x1
    800003a4:	9be080e7          	jalr	-1602(ra) # 80000d5e <acquire>
    switch (c) {
    800003a8:	47d5                	li	a5,21
    800003aa:	0af48463          	beq	s1,a5,80000452 <consoleintr+0xc8>
    800003ae:	0297ca63          	blt	a5,s1,800003e2 <consoleintr+0x58>
    800003b2:	47a1                	li	a5,8
    800003b4:	0ef48563          	beq	s1,a5,8000049e <consoleintr+0x114>
    800003b8:	47c1                	li	a5,16
    800003ba:	10f49863          	bne	s1,a5,800004ca <consoleintr+0x140>
        case C('P'):  // Print process list.
            procdump();
    800003be:	00002097          	auipc	ra,0x2
    800003c2:	2d2080e7          	jalr	722(ra) # 80002690 <procdump>
                }
            }
            break;
    }

    release(&cons.lock);
    800003c6:	00010517          	auipc	a0,0x10
    800003ca:	68a50513          	addi	a0,a0,1674 # 80010a50 <cons>
    800003ce:	00001097          	auipc	ra,0x1
    800003d2:	a44080e7          	jalr	-1468(ra) # 80000e12 <release>
}
    800003d6:	60e2                	ld	ra,24(sp)
    800003d8:	6442                	ld	s0,16(sp)
    800003da:	64a2                	ld	s1,8(sp)
    800003dc:	6902                	ld	s2,0(sp)
    800003de:	6105                	addi	sp,sp,32
    800003e0:	8082                	ret
    switch (c) {
    800003e2:	07f00793          	li	a5,127
    800003e6:	0af48c63          	beq	s1,a5,8000049e <consoleintr+0x114>
            if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE) {
    800003ea:	00010717          	auipc	a4,0x10
    800003ee:	66670713          	addi	a4,a4,1638 # 80010a50 <cons>
    800003f2:	0a072783          	lw	a5,160(a4)
    800003f6:	09872703          	lw	a4,152(a4)
    800003fa:	9f99                	subw	a5,a5,a4
    800003fc:	07f00713          	li	a4,127
    80000400:	fcf763e3          	bltu	a4,a5,800003c6 <consoleintr+0x3c>
                c = (c == '\r') ? '\n' : c;
    80000404:	47b5                	li	a5,13
    80000406:	0cf48563          	beq	s1,a5,800004d0 <consoleintr+0x146>
                consputc(c);
    8000040a:	8526                	mv	a0,s1
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e70080e7          	jalr	-400(ra) # 8000027c <consputc>
                cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000414:	00010797          	auipc	a5,0x10
    80000418:	63c78793          	addi	a5,a5,1596 # 80010a50 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addiw	a3,a4,1
    80000424:	0ad7a023          	sw	a3,160(a5)
    80000428:	07f77713          	andi	a4,a4,127
    8000042c:	97ba                	add	a5,a5,a4
    8000042e:	00978c23          	sb	s1,24(a5)
                if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE) {
    80000432:	47a9                	li	a5,10
    80000434:	0cf48363          	beq	s1,a5,800004fa <consoleintr+0x170>
    80000438:	4791                	li	a5,4
    8000043a:	0cf48063          	beq	s1,a5,800004fa <consoleintr+0x170>
    8000043e:	00010797          	auipc	a5,0x10
    80000442:	6aa7a783          	lw	a5,1706(a5) # 80010ae8 <cons+0x98>
    80000446:	9e9d                	subw	a3,a3,a5
    80000448:	08000793          	li	a5,128
    8000044c:	f6f69de3          	bne	a3,a5,800003c6 <consoleintr+0x3c>
    80000450:	a06d                	j	800004fa <consoleintr+0x170>
            while (cons.e != cons.w &&
    80000452:	00010717          	auipc	a4,0x10
    80000456:	5fe70713          	addi	a4,a4,1534 # 80010a50 <cons>
    8000045a:	0a072783          	lw	a5,160(a4)
    8000045e:	09c72703          	lw	a4,156(a4)
                   cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n') {
    80000462:	00010497          	auipc	s1,0x10
    80000466:	5ee48493          	addi	s1,s1,1518 # 80010a50 <cons>
            while (cons.e != cons.w &&
    8000046a:	4929                	li	s2,10
    8000046c:	f4f70de3          	beq	a4,a5,800003c6 <consoleintr+0x3c>
                   cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n') {
    80000470:	37fd                	addiw	a5,a5,-1
    80000472:	07f7f713          	andi	a4,a5,127
    80000476:	9726                	add	a4,a4,s1
            while (cons.e != cons.w &&
    80000478:	01874703          	lbu	a4,24(a4)
    8000047c:	f52705e3          	beq	a4,s2,800003c6 <consoleintr+0x3c>
                cons.e--;
    80000480:	0af4a023          	sw	a5,160(s1)
                consputc(BACKSPACE);
    80000484:	10000513          	li	a0,256
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	df4080e7          	jalr	-524(ra) # 8000027c <consputc>
            while (cons.e != cons.w &&
    80000490:	0a04a783          	lw	a5,160(s1)
    80000494:	09c4a703          	lw	a4,156(s1)
    80000498:	fcf71ce3          	bne	a4,a5,80000470 <consoleintr+0xe6>
    8000049c:	b72d                	j	800003c6 <consoleintr+0x3c>
            if (cons.e != cons.w) {
    8000049e:	00010717          	auipc	a4,0x10
    800004a2:	5b270713          	addi	a4,a4,1458 # 80010a50 <cons>
    800004a6:	0a072783          	lw	a5,160(a4)
    800004aa:	09c72703          	lw	a4,156(a4)
    800004ae:	f0f70ce3          	beq	a4,a5,800003c6 <consoleintr+0x3c>
                cons.e--;
    800004b2:	37fd                	addiw	a5,a5,-1
    800004b4:	00010717          	auipc	a4,0x10
    800004b8:	62f72e23          	sw	a5,1596(a4) # 80010af0 <cons+0xa0>
                consputc(BACKSPACE);
    800004bc:	10000513          	li	a0,256
    800004c0:	00000097          	auipc	ra,0x0
    800004c4:	dbc080e7          	jalr	-580(ra) # 8000027c <consputc>
    800004c8:	bdfd                	j	800003c6 <consoleintr+0x3c>
            if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE) {
    800004ca:	ee048ee3          	beqz	s1,800003c6 <consoleintr+0x3c>
    800004ce:	bf31                	j	800003ea <consoleintr+0x60>
                consputc(c);
    800004d0:	4529                	li	a0,10
    800004d2:	00000097          	auipc	ra,0x0
    800004d6:	daa080e7          	jalr	-598(ra) # 8000027c <consputc>
                cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800004da:	00010797          	auipc	a5,0x10
    800004de:	57678793          	addi	a5,a5,1398 # 80010a50 <cons>
    800004e2:	0a07a703          	lw	a4,160(a5)
    800004e6:	0017069b          	addiw	a3,a4,1
    800004ea:	0ad7a023          	sw	a3,160(a5)
    800004ee:	07f77713          	andi	a4,a4,127
    800004f2:	97ba                	add	a5,a5,a4
    800004f4:	4729                	li	a4,10
    800004f6:	00e78c23          	sb	a4,24(a5)
                    addCommand();
    800004fa:	00000097          	auipc	ra,0x0
    800004fe:	dc4080e7          	jalr	-572(ra) # 800002be <addCommand>
                    cons.w = cons.e;
    80000502:	00010797          	auipc	a5,0x10
    80000506:	54e78793          	addi	a5,a5,1358 # 80010a50 <cons>
    8000050a:	0a07a703          	lw	a4,160(a5)
    8000050e:	08e7ae23          	sw	a4,156(a5)
                    wakeup(&cons.r);
    80000512:	00010517          	auipc	a0,0x10
    80000516:	5d650513          	addi	a0,a0,1494 # 80010ae8 <cons+0x98>
    8000051a:	00002097          	auipc	ra,0x2
    8000051e:	d26080e7          	jalr	-730(ra) # 80002240 <wakeup>
    80000522:	b555                	j	800003c6 <consoleintr+0x3c>

0000000080000524 <consoleinit>:

void
consoleinit(void) {
    80000524:	1141                	addi	sp,sp,-16
    80000526:	e406                	sd	ra,8(sp)
    80000528:	e022                	sd	s0,0(sp)
    8000052a:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    8000052c:	00008597          	auipc	a1,0x8
    80000530:	ae458593          	addi	a1,a1,-1308 # 80008010 <etext+0x10>
    80000534:	00010517          	auipc	a0,0x10
    80000538:	51c50513          	addi	a0,a0,1308 # 80010a50 <cons>
    8000053c:	00000097          	auipc	ra,0x0
    80000540:	792080e7          	jalr	1938(ra) # 80000cce <initlock>

    uartinit();
    80000544:	00000097          	auipc	ra,0x0
    80000548:	3de080e7          	jalr	990(ra) # 80000922 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    8000054c:	00021797          	auipc	a5,0x21
    80000550:	eec78793          	addi	a5,a5,-276 # 80021438 <devsw>
    80000554:	00000717          	auipc	a4,0x0
    80000558:	c1070713          	addi	a4,a4,-1008 # 80000164 <consoleread>
    8000055c:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    8000055e:	00000717          	auipc	a4,0x0
    80000562:	ba470713          	addi	a4,a4,-1116 # 80000102 <consolewrite>
    80000566:	ef98                	sd	a4,24(a5)
}
    80000568:	60a2                	ld	ra,8(sp)
    8000056a:	6402                	ld	s0,0(sp)
    8000056c:	0141                	addi	sp,sp,16
    8000056e:	8082                	ret

0000000080000570 <sys_history>:

uint64
sys_history(void) {

    if (his.BufferArr[0][0]) {
    80000570:	00010797          	auipc	a5,0x10
    80000574:	5887c783          	lbu	a5,1416(a5) # 80010af8 <his>
    80000578:	e399                	bnez	a5,8000057e <sys_history+0xe>
                printf("requested command: %s\n", his.BufferArr[index]);
            }
        }
    }
    return 0;
}
    8000057a:	4501                	li	a0,0
    8000057c:	8082                	ret
sys_history(void) {
    8000057e:	7139                	addi	sp,sp,-64
    80000580:	fc06                	sd	ra,56(sp)
    80000582:	f822                	sd	s0,48(sp)
    80000584:	f426                	sd	s1,40(sp)
    80000586:	f04a                	sd	s2,32(sp)
    80000588:	ec4e                	sd	s3,24(sp)
    8000058a:	e852                	sd	s4,16(sp)
    8000058c:	0080                	addi	s0,sp,64
        argint(0, &index);
    8000058e:	fcc40593          	addi	a1,s0,-52
    80000592:	4501                	li	a0,0
    80000594:	00002097          	auipc	ra,0x2
    80000598:	78a080e7          	jalr	1930(ra) # 80002d1e <argint>
        for (int i = 0; i < MAX_HISTORY; i++) {
    8000059c:	00010497          	auipc	s1,0x10
    800005a0:	55c48493          	addi	s1,s1,1372 # 80010af8 <his>
    800005a4:	4901                	li	s2,0
        int v =0;
    800005a6:	4701                	li	a4,0
                printf("%s\n", his.BufferArr[i]);
    800005a8:	00008a17          	auipc	s4,0x8
    800005ac:	a70a0a13          	addi	s4,s4,-1424 # 80008018 <etext+0x18>
        for (int i = 0; i < MAX_HISTORY; i++) {
    800005b0:	49c1                	li	s3,16
    800005b2:	a011                	j	800005b6 <sys_history+0x46>
    800005b4:	893e                	mv	s2,a5
            if (his.BufferArr[i][0]) {
    800005b6:	0004c783          	lbu	a5,0(s1)
    800005ba:	cf99                	beqz	a5,800005d8 <sys_history+0x68>
                printf("%s\n", his.BufferArr[i]);
    800005bc:	85a6                	mv	a1,s1
    800005be:	8552                	mv	a0,s4
    800005c0:	00000097          	auipc	ra,0x0
    800005c4:	150080e7          	jalr	336(ra) # 80000710 <printf>
        for (int i = 0; i < MAX_HISTORY; i++) {
    800005c8:	0019079b          	addiw	a5,s2,1
    800005cc:	08048493          	addi	s1,s1,128
    800005d0:	874a                	mv	a4,s2
    800005d2:	ff3791e3          	bne	a5,s3,800005b4 <sys_history+0x44>
    800005d6:	473d                	li	a4,15
        if (index >= 0) {
    800005d8:	fcc42583          	lw	a1,-52(s0)
    800005dc:	0005cc63          	bltz	a1,800005f4 <sys_history+0x84>
            if (index > v) {
    800005e0:	02b75363          	bge	a4,a1,80000606 <sys_history+0x96>
                printf("ID not found!\n");
    800005e4:	00008517          	auipc	a0,0x8
    800005e8:	a3c50513          	addi	a0,a0,-1476 # 80008020 <etext+0x20>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	124080e7          	jalr	292(ra) # 80000710 <printf>
}
    800005f4:	4501                	li	a0,0
    800005f6:	70e2                	ld	ra,56(sp)
    800005f8:	7442                	ld	s0,48(sp)
    800005fa:	74a2                	ld	s1,40(sp)
    800005fc:	7902                	ld	s2,32(sp)
    800005fe:	69e2                	ld	s3,24(sp)
    80000600:	6a42                	ld	s4,16(sp)
    80000602:	6121                	addi	sp,sp,64
    80000604:	8082                	ret
                printf("requested command: %s\n", his.BufferArr[index]);
    80000606:	059e                	slli	a1,a1,0x7
    80000608:	00010797          	auipc	a5,0x10
    8000060c:	4f078793          	addi	a5,a5,1264 # 80010af8 <his>
    80000610:	95be                	add	a1,a1,a5
    80000612:	00008517          	auipc	a0,0x8
    80000616:	a1e50513          	addi	a0,a0,-1506 # 80008030 <etext+0x30>
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	0f6080e7          	jalr	246(ra) # 80000710 <printf>
    80000622:	bfc9                	j	800005f4 <sys_history+0x84>

0000000080000624 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000624:	7179                	addi	sp,sp,-48
    80000626:	f406                	sd	ra,40(sp)
    80000628:	f022                	sd	s0,32(sp)
    8000062a:	ec26                	sd	s1,24(sp)
    8000062c:	e84a                	sd	s2,16(sp)
    8000062e:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000630:	c219                	beqz	a2,80000636 <printint+0x12>
    80000632:	08054663          	bltz	a0,800006be <printint+0x9a>
    x = -xx;
  else
    x = xx;
    80000636:	2501                	sext.w	a0,a0
    80000638:	4881                	li	a7,0
    8000063a:	fd040693          	addi	a3,s0,-48

  i = 0;
    8000063e:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000640:	2581                	sext.w	a1,a1
    80000642:	00008617          	auipc	a2,0x8
    80000646:	a2e60613          	addi	a2,a2,-1490 # 80008070 <digits>
    8000064a:	883a                	mv	a6,a4
    8000064c:	2705                	addiw	a4,a4,1
    8000064e:	02b577bb          	remuw	a5,a0,a1
    80000652:	1782                	slli	a5,a5,0x20
    80000654:	9381                	srli	a5,a5,0x20
    80000656:	97b2                	add	a5,a5,a2
    80000658:	0007c783          	lbu	a5,0(a5)
    8000065c:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000660:	0005079b          	sext.w	a5,a0
    80000664:	02b5553b          	divuw	a0,a0,a1
    80000668:	0685                	addi	a3,a3,1
    8000066a:	feb7f0e3          	bgeu	a5,a1,8000064a <printint+0x26>

  if(sign)
    8000066e:	00088b63          	beqz	a7,80000684 <printint+0x60>
    buf[i++] = '-';
    80000672:	fe040793          	addi	a5,s0,-32
    80000676:	973e                	add	a4,a4,a5
    80000678:	02d00793          	li	a5,45
    8000067c:	fef70823          	sb	a5,-16(a4)
    80000680:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000684:	02e05763          	blez	a4,800006b2 <printint+0x8e>
    80000688:	fd040793          	addi	a5,s0,-48
    8000068c:	00e784b3          	add	s1,a5,a4
    80000690:	fff78913          	addi	s2,a5,-1
    80000694:	993a                	add	s2,s2,a4
    80000696:	377d                	addiw	a4,a4,-1
    80000698:	1702                	slli	a4,a4,0x20
    8000069a:	9301                	srli	a4,a4,0x20
    8000069c:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    800006a0:	fff4c503          	lbu	a0,-1(s1)
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bd8080e7          	jalr	-1064(ra) # 8000027c <consputc>
  while(--i >= 0)
    800006ac:	14fd                	addi	s1,s1,-1
    800006ae:	ff2499e3          	bne	s1,s2,800006a0 <printint+0x7c>
}
    800006b2:	70a2                	ld	ra,40(sp)
    800006b4:	7402                	ld	s0,32(sp)
    800006b6:	64e2                	ld	s1,24(sp)
    800006b8:	6942                	ld	s2,16(sp)
    800006ba:	6145                	addi	sp,sp,48
    800006bc:	8082                	ret
    x = -xx;
    800006be:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    800006c2:	4885                	li	a7,1
    x = -xx;
    800006c4:	bf9d                	j	8000063a <printint+0x16>

00000000800006c6 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    800006c6:	1101                	addi	sp,sp,-32
    800006c8:	ec06                	sd	ra,24(sp)
    800006ca:	e822                	sd	s0,16(sp)
    800006cc:	e426                	sd	s1,8(sp)
    800006ce:	1000                	addi	s0,sp,32
    800006d0:	84aa                	mv	s1,a0
  pr.locking = 0;
    800006d2:	00011797          	auipc	a5,0x11
    800006d6:	c807a723          	sw	zero,-882(a5) # 80011360 <pr+0x18>
  printf("panic: ");
    800006da:	00008517          	auipc	a0,0x8
    800006de:	96e50513          	addi	a0,a0,-1682 # 80008048 <etext+0x48>
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	02e080e7          	jalr	46(ra) # 80000710 <printf>
  printf(s);
    800006ea:	8526                	mv	a0,s1
    800006ec:	00000097          	auipc	ra,0x0
    800006f0:	024080e7          	jalr	36(ra) # 80000710 <printf>
  printf("\n");
    800006f4:	00008517          	auipc	a0,0x8
    800006f8:	a0450513          	addi	a0,a0,-1532 # 800080f8 <digits+0x88>
    800006fc:	00000097          	auipc	ra,0x0
    80000700:	014080e7          	jalr	20(ra) # 80000710 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000704:	4785                	li	a5,1
    80000706:	00008717          	auipc	a4,0x8
    8000070a:	1cf72523          	sw	a5,458(a4) # 800088d0 <panicked>
  for(;;)
    8000070e:	a001                	j	8000070e <panic+0x48>

0000000080000710 <printf>:
{
    80000710:	7131                	addi	sp,sp,-192
    80000712:	fc86                	sd	ra,120(sp)
    80000714:	f8a2                	sd	s0,112(sp)
    80000716:	f4a6                	sd	s1,104(sp)
    80000718:	f0ca                	sd	s2,96(sp)
    8000071a:	ecce                	sd	s3,88(sp)
    8000071c:	e8d2                	sd	s4,80(sp)
    8000071e:	e4d6                	sd	s5,72(sp)
    80000720:	e0da                	sd	s6,64(sp)
    80000722:	fc5e                	sd	s7,56(sp)
    80000724:	f862                	sd	s8,48(sp)
    80000726:	f466                	sd	s9,40(sp)
    80000728:	f06a                	sd	s10,32(sp)
    8000072a:	ec6e                	sd	s11,24(sp)
    8000072c:	0100                	addi	s0,sp,128
    8000072e:	8a2a                	mv	s4,a0
    80000730:	e40c                	sd	a1,8(s0)
    80000732:	e810                	sd	a2,16(s0)
    80000734:	ec14                	sd	a3,24(s0)
    80000736:	f018                	sd	a4,32(s0)
    80000738:	f41c                	sd	a5,40(s0)
    8000073a:	03043823          	sd	a6,48(s0)
    8000073e:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000742:	00011d97          	auipc	s11,0x11
    80000746:	c1edad83          	lw	s11,-994(s11) # 80011360 <pr+0x18>
  if(locking)
    8000074a:	020d9b63          	bnez	s11,80000780 <printf+0x70>
  if (fmt == 0)
    8000074e:	040a0263          	beqz	s4,80000792 <printf+0x82>
  va_start(ap, fmt);
    80000752:	00840793          	addi	a5,s0,8
    80000756:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000075a:	000a4503          	lbu	a0,0(s4)
    8000075e:	14050f63          	beqz	a0,800008bc <printf+0x1ac>
    80000762:	4981                	li	s3,0
    if(c != '%'){
    80000764:	02500a93          	li	s5,37
    switch(c){
    80000768:	07000b93          	li	s7,112
  consputc('x');
    8000076c:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000076e:	00008b17          	auipc	s6,0x8
    80000772:	902b0b13          	addi	s6,s6,-1790 # 80008070 <digits>
    switch(c){
    80000776:	07300c93          	li	s9,115
    8000077a:	06400c13          	li	s8,100
    8000077e:	a82d                	j	800007b8 <printf+0xa8>
    acquire(&pr.lock);
    80000780:	00011517          	auipc	a0,0x11
    80000784:	bc850513          	addi	a0,a0,-1080 # 80011348 <pr>
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	5d6080e7          	jalr	1494(ra) # 80000d5e <acquire>
    80000790:	bf7d                	j	8000074e <printf+0x3e>
    panic("null fmt");
    80000792:	00008517          	auipc	a0,0x8
    80000796:	8c650513          	addi	a0,a0,-1850 # 80008058 <etext+0x58>
    8000079a:	00000097          	auipc	ra,0x0
    8000079e:	f2c080e7          	jalr	-212(ra) # 800006c6 <panic>
      consputc(c);
    800007a2:	00000097          	auipc	ra,0x0
    800007a6:	ada080e7          	jalr	-1318(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800007aa:	2985                	addiw	s3,s3,1
    800007ac:	013a07b3          	add	a5,s4,s3
    800007b0:	0007c503          	lbu	a0,0(a5)
    800007b4:	10050463          	beqz	a0,800008bc <printf+0x1ac>
    if(c != '%'){
    800007b8:	ff5515e3          	bne	a0,s5,800007a2 <printf+0x92>
    c = fmt[++i] & 0xff;
    800007bc:	2985                	addiw	s3,s3,1
    800007be:	013a07b3          	add	a5,s4,s3
    800007c2:	0007c783          	lbu	a5,0(a5)
    800007c6:	0007849b          	sext.w	s1,a5
    if(c == 0)
    800007ca:	cbed                	beqz	a5,800008bc <printf+0x1ac>
    switch(c){
    800007cc:	05778a63          	beq	a5,s7,80000820 <printf+0x110>
    800007d0:	02fbf663          	bgeu	s7,a5,800007fc <printf+0xec>
    800007d4:	09978863          	beq	a5,s9,80000864 <printf+0x154>
    800007d8:	07800713          	li	a4,120
    800007dc:	0ce79563          	bne	a5,a4,800008a6 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    800007e0:	f8843783          	ld	a5,-120(s0)
    800007e4:	00878713          	addi	a4,a5,8
    800007e8:	f8e43423          	sd	a4,-120(s0)
    800007ec:	4605                	li	a2,1
    800007ee:	85ea                	mv	a1,s10
    800007f0:	4388                	lw	a0,0(a5)
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	e32080e7          	jalr	-462(ra) # 80000624 <printint>
      break;
    800007fa:	bf45                	j	800007aa <printf+0x9a>
    switch(c){
    800007fc:	09578f63          	beq	a5,s5,8000089a <printf+0x18a>
    80000800:	0b879363          	bne	a5,s8,800008a6 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000804:	f8843783          	ld	a5,-120(s0)
    80000808:	00878713          	addi	a4,a5,8
    8000080c:	f8e43423          	sd	a4,-120(s0)
    80000810:	4605                	li	a2,1
    80000812:	45a9                	li	a1,10
    80000814:	4388                	lw	a0,0(a5)
    80000816:	00000097          	auipc	ra,0x0
    8000081a:	e0e080e7          	jalr	-498(ra) # 80000624 <printint>
      break;
    8000081e:	b771                	j	800007aa <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000820:	f8843783          	ld	a5,-120(s0)
    80000824:	00878713          	addi	a4,a5,8
    80000828:	f8e43423          	sd	a4,-120(s0)
    8000082c:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000830:	03000513          	li	a0,48
    80000834:	00000097          	auipc	ra,0x0
    80000838:	a48080e7          	jalr	-1464(ra) # 8000027c <consputc>
  consputc('x');
    8000083c:	07800513          	li	a0,120
    80000840:	00000097          	auipc	ra,0x0
    80000844:	a3c080e7          	jalr	-1476(ra) # 8000027c <consputc>
    80000848:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000084a:	03c95793          	srli	a5,s2,0x3c
    8000084e:	97da                	add	a5,a5,s6
    80000850:	0007c503          	lbu	a0,0(a5)
    80000854:	00000097          	auipc	ra,0x0
    80000858:	a28080e7          	jalr	-1496(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000085c:	0912                	slli	s2,s2,0x4
    8000085e:	34fd                	addiw	s1,s1,-1
    80000860:	f4ed                	bnez	s1,8000084a <printf+0x13a>
    80000862:	b7a1                	j	800007aa <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000864:	f8843783          	ld	a5,-120(s0)
    80000868:	00878713          	addi	a4,a5,8
    8000086c:	f8e43423          	sd	a4,-120(s0)
    80000870:	6384                	ld	s1,0(a5)
    80000872:	cc89                	beqz	s1,8000088c <printf+0x17c>
      for(; *s; s++)
    80000874:	0004c503          	lbu	a0,0(s1)
    80000878:	d90d                	beqz	a0,800007aa <printf+0x9a>
        consputc(*s);
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	a02080e7          	jalr	-1534(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000882:	0485                	addi	s1,s1,1
    80000884:	0004c503          	lbu	a0,0(s1)
    80000888:	f96d                	bnez	a0,8000087a <printf+0x16a>
    8000088a:	b705                	j	800007aa <printf+0x9a>
        s = "(null)";
    8000088c:	00007497          	auipc	s1,0x7
    80000890:	7c448493          	addi	s1,s1,1988 # 80008050 <etext+0x50>
      for(; *s; s++)
    80000894:	02800513          	li	a0,40
    80000898:	b7cd                	j	8000087a <printf+0x16a>
      consputc('%');
    8000089a:	8556                	mv	a0,s5
    8000089c:	00000097          	auipc	ra,0x0
    800008a0:	9e0080e7          	jalr	-1568(ra) # 8000027c <consputc>
      break;
    800008a4:	b719                	j	800007aa <printf+0x9a>
      consputc('%');
    800008a6:	8556                	mv	a0,s5
    800008a8:	00000097          	auipc	ra,0x0
    800008ac:	9d4080e7          	jalr	-1580(ra) # 8000027c <consputc>
      consputc(c);
    800008b0:	8526                	mv	a0,s1
    800008b2:	00000097          	auipc	ra,0x0
    800008b6:	9ca080e7          	jalr	-1590(ra) # 8000027c <consputc>
      break;
    800008ba:	bdc5                	j	800007aa <printf+0x9a>
  if(locking)
    800008bc:	020d9163          	bnez	s11,800008de <printf+0x1ce>
}
    800008c0:	70e6                	ld	ra,120(sp)
    800008c2:	7446                	ld	s0,112(sp)
    800008c4:	74a6                	ld	s1,104(sp)
    800008c6:	7906                	ld	s2,96(sp)
    800008c8:	69e6                	ld	s3,88(sp)
    800008ca:	6a46                	ld	s4,80(sp)
    800008cc:	6aa6                	ld	s5,72(sp)
    800008ce:	6b06                	ld	s6,64(sp)
    800008d0:	7be2                	ld	s7,56(sp)
    800008d2:	7c42                	ld	s8,48(sp)
    800008d4:	7ca2                	ld	s9,40(sp)
    800008d6:	7d02                	ld	s10,32(sp)
    800008d8:	6de2                	ld	s11,24(sp)
    800008da:	6129                	addi	sp,sp,192
    800008dc:	8082                	ret
    release(&pr.lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	a6a50513          	addi	a0,a0,-1430 # 80011348 <pr>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	52c080e7          	jalr	1324(ra) # 80000e12 <release>
}
    800008ee:	bfc9                	j	800008c0 <printf+0x1b0>

00000000800008f0 <printfinit>:
    ;
}

void
printfinit(void)
{
    800008f0:	1101                	addi	sp,sp,-32
    800008f2:	ec06                	sd	ra,24(sp)
    800008f4:	e822                	sd	s0,16(sp)
    800008f6:	e426                	sd	s1,8(sp)
    800008f8:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800008fa:	00011497          	auipc	s1,0x11
    800008fe:	a4e48493          	addi	s1,s1,-1458 # 80011348 <pr>
    80000902:	00007597          	auipc	a1,0x7
    80000906:	76658593          	addi	a1,a1,1894 # 80008068 <etext+0x68>
    8000090a:	8526                	mv	a0,s1
    8000090c:	00000097          	auipc	ra,0x0
    80000910:	3c2080e7          	jalr	962(ra) # 80000cce <initlock>
  pr.locking = 1;
    80000914:	4785                	li	a5,1
    80000916:	cc9c                	sw	a5,24(s1)
}
    80000918:	60e2                	ld	ra,24(sp)
    8000091a:	6442                	ld	s0,16(sp)
    8000091c:	64a2                	ld	s1,8(sp)
    8000091e:	6105                	addi	sp,sp,32
    80000920:	8082                	ret

0000000080000922 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000922:	1141                	addi	sp,sp,-16
    80000924:	e406                	sd	ra,8(sp)
    80000926:	e022                	sd	s0,0(sp)
    80000928:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000092a:	100007b7          	lui	a5,0x10000
    8000092e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000932:	f8000713          	li	a4,-128
    80000936:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000093a:	470d                	li	a4,3
    8000093c:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000940:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000944:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000948:	469d                	li	a3,7
    8000094a:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000094e:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000952:	00007597          	auipc	a1,0x7
    80000956:	73658593          	addi	a1,a1,1846 # 80008088 <digits+0x18>
    8000095a:	00011517          	auipc	a0,0x11
    8000095e:	a0e50513          	addi	a0,a0,-1522 # 80011368 <uart_tx_lock>
    80000962:	00000097          	auipc	ra,0x0
    80000966:	36c080e7          	jalr	876(ra) # 80000cce <initlock>
}
    8000096a:	60a2                	ld	ra,8(sp)
    8000096c:	6402                	ld	s0,0(sp)
    8000096e:	0141                	addi	sp,sp,16
    80000970:	8082                	ret

0000000080000972 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000972:	1101                	addi	sp,sp,-32
    80000974:	ec06                	sd	ra,24(sp)
    80000976:	e822                	sd	s0,16(sp)
    80000978:	e426                	sd	s1,8(sp)
    8000097a:	1000                	addi	s0,sp,32
    8000097c:	84aa                	mv	s1,a0
  push_off();
    8000097e:	00000097          	auipc	ra,0x0
    80000982:	394080e7          	jalr	916(ra) # 80000d12 <push_off>

  if(panicked){
    80000986:	00008797          	auipc	a5,0x8
    8000098a:	f4a7a783          	lw	a5,-182(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000098e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000992:	c391                	beqz	a5,80000996 <uartputc_sync+0x24>
    for(;;)
    80000994:	a001                	j	80000994 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000996:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000099a:	0207f793          	andi	a5,a5,32
    8000099e:	dfe5                	beqz	a5,80000996 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    800009a0:	0ff4f513          	andi	a0,s1,255
    800009a4:	100007b7          	lui	a5,0x10000
    800009a8:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    800009ac:	00000097          	auipc	ra,0x0
    800009b0:	406080e7          	jalr	1030(ra) # 80000db2 <pop_off>
}
    800009b4:	60e2                	ld	ra,24(sp)
    800009b6:	6442                	ld	s0,16(sp)
    800009b8:	64a2                	ld	s1,8(sp)
    800009ba:	6105                	addi	sp,sp,32
    800009bc:	8082                	ret

00000000800009be <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800009be:	00008797          	auipc	a5,0x8
    800009c2:	f1a7b783          	ld	a5,-230(a5) # 800088d8 <uart_tx_r>
    800009c6:	00008717          	auipc	a4,0x8
    800009ca:	f1a73703          	ld	a4,-230(a4) # 800088e0 <uart_tx_w>
    800009ce:	06f70a63          	beq	a4,a5,80000a42 <uartstart+0x84>
{
    800009d2:	7139                	addi	sp,sp,-64
    800009d4:	fc06                	sd	ra,56(sp)
    800009d6:	f822                	sd	s0,48(sp)
    800009d8:	f426                	sd	s1,40(sp)
    800009da:	f04a                	sd	s2,32(sp)
    800009dc:	ec4e                	sd	s3,24(sp)
    800009de:	e852                	sd	s4,16(sp)
    800009e0:	e456                	sd	s5,8(sp)
    800009e2:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800009e4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800009e8:	00011a17          	auipc	s4,0x11
    800009ec:	980a0a13          	addi	s4,s4,-1664 # 80011368 <uart_tx_lock>
    uart_tx_r += 1;
    800009f0:	00008497          	auipc	s1,0x8
    800009f4:	ee848493          	addi	s1,s1,-280 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800009f8:	00008997          	auipc	s3,0x8
    800009fc:	ee898993          	addi	s3,s3,-280 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000a00:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000a04:	02077713          	andi	a4,a4,32
    80000a08:	c705                	beqz	a4,80000a30 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000a0a:	01f7f713          	andi	a4,a5,31
    80000a0e:	9752                	add	a4,a4,s4
    80000a10:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000a14:	0785                	addi	a5,a5,1
    80000a16:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00002097          	auipc	ra,0x2
    80000a1e:	826080e7          	jalr	-2010(ra) # 80002240 <wakeup>
    
    WriteReg(THR, c);
    80000a22:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000a26:	609c                	ld	a5,0(s1)
    80000a28:	0009b703          	ld	a4,0(s3)
    80000a2c:	fcf71ae3          	bne	a4,a5,80000a00 <uartstart+0x42>
  }
}
    80000a30:	70e2                	ld	ra,56(sp)
    80000a32:	7442                	ld	s0,48(sp)
    80000a34:	74a2                	ld	s1,40(sp)
    80000a36:	7902                	ld	s2,32(sp)
    80000a38:	69e2                	ld	s3,24(sp)
    80000a3a:	6a42                	ld	s4,16(sp)
    80000a3c:	6aa2                	ld	s5,8(sp)
    80000a3e:	6121                	addi	sp,sp,64
    80000a40:	8082                	ret
    80000a42:	8082                	ret

0000000080000a44 <uartputc>:
{
    80000a44:	7179                	addi	sp,sp,-48
    80000a46:	f406                	sd	ra,40(sp)
    80000a48:	f022                	sd	s0,32(sp)
    80000a4a:	ec26                	sd	s1,24(sp)
    80000a4c:	e84a                	sd	s2,16(sp)
    80000a4e:	e44e                	sd	s3,8(sp)
    80000a50:	e052                	sd	s4,0(sp)
    80000a52:	1800                	addi	s0,sp,48
    80000a54:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000a56:	00011517          	auipc	a0,0x11
    80000a5a:	91250513          	addi	a0,a0,-1774 # 80011368 <uart_tx_lock>
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	300080e7          	jalr	768(ra) # 80000d5e <acquire>
  if(panicked){
    80000a66:	00008797          	auipc	a5,0x8
    80000a6a:	e6a7a783          	lw	a5,-406(a5) # 800088d0 <panicked>
    80000a6e:	e7c9                	bnez	a5,80000af8 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000a70:	00008717          	auipc	a4,0x8
    80000a74:	e7073703          	ld	a4,-400(a4) # 800088e0 <uart_tx_w>
    80000a78:	00008797          	auipc	a5,0x8
    80000a7c:	e607b783          	ld	a5,-416(a5) # 800088d8 <uart_tx_r>
    80000a80:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000a84:	00011997          	auipc	s3,0x11
    80000a88:	8e498993          	addi	s3,s3,-1820 # 80011368 <uart_tx_lock>
    80000a8c:	00008497          	auipc	s1,0x8
    80000a90:	e4c48493          	addi	s1,s1,-436 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000a94:	00008917          	auipc	s2,0x8
    80000a98:	e4c90913          	addi	s2,s2,-436 # 800088e0 <uart_tx_w>
    80000a9c:	00e79f63          	bne	a5,a4,80000aba <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000aa0:	85ce                	mv	a1,s3
    80000aa2:	8526                	mv	a0,s1
    80000aa4:	00001097          	auipc	ra,0x1
    80000aa8:	738080e7          	jalr	1848(ra) # 800021dc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000aac:	00093703          	ld	a4,0(s2)
    80000ab0:	609c                	ld	a5,0(s1)
    80000ab2:	02078793          	addi	a5,a5,32
    80000ab6:	fee785e3          	beq	a5,a4,80000aa0 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000aba:	00011497          	auipc	s1,0x11
    80000abe:	8ae48493          	addi	s1,s1,-1874 # 80011368 <uart_tx_lock>
    80000ac2:	01f77793          	andi	a5,a4,31
    80000ac6:	97a6                	add	a5,a5,s1
    80000ac8:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000acc:	0705                	addi	a4,a4,1
    80000ace:	00008797          	auipc	a5,0x8
    80000ad2:	e0e7b923          	sd	a4,-494(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	ee8080e7          	jalr	-280(ra) # 800009be <uartstart>
  release(&uart_tx_lock);
    80000ade:	8526                	mv	a0,s1
    80000ae0:	00000097          	auipc	ra,0x0
    80000ae4:	332080e7          	jalr	818(ra) # 80000e12 <release>
}
    80000ae8:	70a2                	ld	ra,40(sp)
    80000aea:	7402                	ld	s0,32(sp)
    80000aec:	64e2                	ld	s1,24(sp)
    80000aee:	6942                	ld	s2,16(sp)
    80000af0:	69a2                	ld	s3,8(sp)
    80000af2:	6a02                	ld	s4,0(sp)
    80000af4:	6145                	addi	sp,sp,48
    80000af6:	8082                	ret
    for(;;)
    80000af8:	a001                	j	80000af8 <uartputc+0xb4>

0000000080000afa <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000afa:	1141                	addi	sp,sp,-16
    80000afc:	e422                	sd	s0,8(sp)
    80000afe:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000b00:	100007b7          	lui	a5,0x10000
    80000b04:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000b08:	8b85                	andi	a5,a5,1
    80000b0a:	cb91                	beqz	a5,80000b1e <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000b0c:	100007b7          	lui	a5,0x10000
    80000b10:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000b14:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000b18:	6422                	ld	s0,8(sp)
    80000b1a:	0141                	addi	sp,sp,16
    80000b1c:	8082                	ret
    return -1;
    80000b1e:	557d                	li	a0,-1
    80000b20:	bfe5                	j	80000b18 <uartgetc+0x1e>

0000000080000b22 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000b22:	1101                	addi	sp,sp,-32
    80000b24:	ec06                	sd	ra,24(sp)
    80000b26:	e822                	sd	s0,16(sp)
    80000b28:	e426                	sd	s1,8(sp)
    80000b2a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000b2c:	54fd                	li	s1,-1
    80000b2e:	a029                	j	80000b38 <uartintr+0x16>
      break;
    consoleintr(c);
    80000b30:	00000097          	auipc	ra,0x0
    80000b34:	85a080e7          	jalr	-1958(ra) # 8000038a <consoleintr>
    int c = uartgetc();
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	fc2080e7          	jalr	-62(ra) # 80000afa <uartgetc>
    if(c == -1)
    80000b40:	fe9518e3          	bne	a0,s1,80000b30 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000b44:	00011497          	auipc	s1,0x11
    80000b48:	82448493          	addi	s1,s1,-2012 # 80011368 <uart_tx_lock>
    80000b4c:	8526                	mv	a0,s1
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	210080e7          	jalr	528(ra) # 80000d5e <acquire>
  uartstart();
    80000b56:	00000097          	auipc	ra,0x0
    80000b5a:	e68080e7          	jalr	-408(ra) # 800009be <uartstart>
  release(&uart_tx_lock);
    80000b5e:	8526                	mv	a0,s1
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	2b2080e7          	jalr	690(ra) # 80000e12 <release>
}
    80000b68:	60e2                	ld	ra,24(sp)
    80000b6a:	6442                	ld	s0,16(sp)
    80000b6c:	64a2                	ld	s1,8(sp)
    80000b6e:	6105                	addi	sp,sp,32
    80000b70:	8082                	ret

0000000080000b72 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	e04a                	sd	s2,0(sp)
    80000b7c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b7e:	03451793          	slli	a5,a0,0x34
    80000b82:	ebb9                	bnez	a5,80000bd8 <kfree+0x66>
    80000b84:	84aa                	mv	s1,a0
    80000b86:	00022797          	auipc	a5,0x22
    80000b8a:	a4a78793          	addi	a5,a5,-1462 # 800225d0 <end>
    80000b8e:	04f56563          	bltu	a0,a5,80000bd8 <kfree+0x66>
    80000b92:	47c5                	li	a5,17
    80000b94:	07ee                	slli	a5,a5,0x1b
    80000b96:	04f57163          	bgeu	a0,a5,80000bd8 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000b9a:	6605                	lui	a2,0x1
    80000b9c:	4585                	li	a1,1
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	2bc080e7          	jalr	700(ra) # 80000e5a <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ba6:	00010917          	auipc	s2,0x10
    80000baa:	7fa90913          	addi	s2,s2,2042 # 800113a0 <kmem>
    80000bae:	854a                	mv	a0,s2
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	1ae080e7          	jalr	430(ra) # 80000d5e <acquire>
  r->next = kmem.freelist;
    80000bb8:	01893783          	ld	a5,24(s2)
    80000bbc:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000bbe:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000bc2:	854a                	mv	a0,s2
    80000bc4:	00000097          	auipc	ra,0x0
    80000bc8:	24e080e7          	jalr	590(ra) # 80000e12 <release>
}
    80000bcc:	60e2                	ld	ra,24(sp)
    80000bce:	6442                	ld	s0,16(sp)
    80000bd0:	64a2                	ld	s1,8(sp)
    80000bd2:	6902                	ld	s2,0(sp)
    80000bd4:	6105                	addi	sp,sp,32
    80000bd6:	8082                	ret
    panic("kfree");
    80000bd8:	00007517          	auipc	a0,0x7
    80000bdc:	4b850513          	addi	a0,a0,1208 # 80008090 <digits+0x20>
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	ae6080e7          	jalr	-1306(ra) # 800006c6 <panic>

0000000080000be8 <freerange>:
{
    80000be8:	7179                	addi	sp,sp,-48
    80000bea:	f406                	sd	ra,40(sp)
    80000bec:	f022                	sd	s0,32(sp)
    80000bee:	ec26                	sd	s1,24(sp)
    80000bf0:	e84a                	sd	s2,16(sp)
    80000bf2:	e44e                	sd	s3,8(sp)
    80000bf4:	e052                	sd	s4,0(sp)
    80000bf6:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000bf8:	6785                	lui	a5,0x1
    80000bfa:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000bfe:	94aa                	add	s1,s1,a0
    80000c00:	757d                	lui	a0,0xfffff
    80000c02:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000c04:	94be                	add	s1,s1,a5
    80000c06:	0095ee63          	bltu	a1,s1,80000c22 <freerange+0x3a>
    80000c0a:	892e                	mv	s2,a1
    kfree(p);
    80000c0c:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000c0e:	6985                	lui	s3,0x1
    kfree(p);
    80000c10:	01448533          	add	a0,s1,s4
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f5e080e7          	jalr	-162(ra) # 80000b72 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000c1c:	94ce                	add	s1,s1,s3
    80000c1e:	fe9979e3          	bgeu	s2,s1,80000c10 <freerange+0x28>
}
    80000c22:	70a2                	ld	ra,40(sp)
    80000c24:	7402                	ld	s0,32(sp)
    80000c26:	64e2                	ld	s1,24(sp)
    80000c28:	6942                	ld	s2,16(sp)
    80000c2a:	69a2                	ld	s3,8(sp)
    80000c2c:	6a02                	ld	s4,0(sp)
    80000c2e:	6145                	addi	sp,sp,48
    80000c30:	8082                	ret

0000000080000c32 <kinit>:
{
    80000c32:	1141                	addi	sp,sp,-16
    80000c34:	e406                	sd	ra,8(sp)
    80000c36:	e022                	sd	s0,0(sp)
    80000c38:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000c3a:	00007597          	auipc	a1,0x7
    80000c3e:	45e58593          	addi	a1,a1,1118 # 80008098 <digits+0x28>
    80000c42:	00010517          	auipc	a0,0x10
    80000c46:	75e50513          	addi	a0,a0,1886 # 800113a0 <kmem>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	084080e7          	jalr	132(ra) # 80000cce <initlock>
  freerange(end, (void*)PHYSTOP);
    80000c52:	45c5                	li	a1,17
    80000c54:	05ee                	slli	a1,a1,0x1b
    80000c56:	00022517          	auipc	a0,0x22
    80000c5a:	97a50513          	addi	a0,a0,-1670 # 800225d0 <end>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f8a080e7          	jalr	-118(ra) # 80000be8 <freerange>
}
    80000c66:	60a2                	ld	ra,8(sp)
    80000c68:	6402                	ld	s0,0(sp)
    80000c6a:	0141                	addi	sp,sp,16
    80000c6c:	8082                	ret

0000000080000c6e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c6e:	1101                	addi	sp,sp,-32
    80000c70:	ec06                	sd	ra,24(sp)
    80000c72:	e822                	sd	s0,16(sp)
    80000c74:	e426                	sd	s1,8(sp)
    80000c76:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c78:	00010497          	auipc	s1,0x10
    80000c7c:	72848493          	addi	s1,s1,1832 # 800113a0 <kmem>
    80000c80:	8526                	mv	a0,s1
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	0dc080e7          	jalr	220(ra) # 80000d5e <acquire>
  r = kmem.freelist;
    80000c8a:	6c84                	ld	s1,24(s1)
  if(r)
    80000c8c:	c885                	beqz	s1,80000cbc <kalloc+0x4e>
    kmem.freelist = r->next;
    80000c8e:	609c                	ld	a5,0(s1)
    80000c90:	00010517          	auipc	a0,0x10
    80000c94:	71050513          	addi	a0,a0,1808 # 800113a0 <kmem>
    80000c98:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	178080e7          	jalr	376(ra) # 80000e12 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ca2:	6605                	lui	a2,0x1
    80000ca4:	4595                	li	a1,5
    80000ca6:	8526                	mv	a0,s1
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	1b2080e7          	jalr	434(ra) # 80000e5a <memset>
  return (void*)r;
}
    80000cb0:	8526                	mv	a0,s1
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
  release(&kmem.lock);
    80000cbc:	00010517          	auipc	a0,0x10
    80000cc0:	6e450513          	addi	a0,a0,1764 # 800113a0 <kmem>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	14e080e7          	jalr	334(ra) # 80000e12 <release>
  if(r)
    80000ccc:	b7d5                	j	80000cb0 <kalloc+0x42>

0000000080000cce <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cd4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cd6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cda:	00053823          	sd	zero,16(a0)
}
    80000cde:	6422                	ld	s0,8(sp)
    80000ce0:	0141                	addi	sp,sp,16
    80000ce2:	8082                	ret

0000000080000ce4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ce4:	411c                	lw	a5,0(a0)
    80000ce6:	e399                	bnez	a5,80000cec <holding+0x8>
    80000ce8:	4501                	li	a0,0
  return r;
}
    80000cea:	8082                	ret
{
    80000cec:	1101                	addi	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cf6:	6904                	ld	s1,16(a0)
    80000cf8:	00001097          	auipc	ra,0x1
    80000cfc:	e20080e7          	jalr	-480(ra) # 80001b18 <mycpu>
    80000d00:	40a48533          	sub	a0,s1,a0
    80000d04:	00153513          	seqz	a0,a0
}
    80000d08:	60e2                	ld	ra,24(sp)
    80000d0a:	6442                	ld	s0,16(sp)
    80000d0c:	64a2                	ld	s1,8(sp)
    80000d0e:	6105                	addi	sp,sp,32
    80000d10:	8082                	ret

0000000080000d12 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d12:	1101                	addi	sp,sp,-32
    80000d14:	ec06                	sd	ra,24(sp)
    80000d16:	e822                	sd	s0,16(sp)
    80000d18:	e426                	sd	s1,8(sp)
    80000d1a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1c:	100024f3          	csrr	s1,sstatus
    80000d20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d24:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d26:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d2a:	00001097          	auipc	ra,0x1
    80000d2e:	dee080e7          	jalr	-530(ra) # 80001b18 <mycpu>
    80000d32:	5d3c                	lw	a5,120(a0)
    80000d34:	cf89                	beqz	a5,80000d4e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d36:	00001097          	auipc	ra,0x1
    80000d3a:	de2080e7          	jalr	-542(ra) # 80001b18 <mycpu>
    80000d3e:	5d3c                	lw	a5,120(a0)
    80000d40:	2785                	addiw	a5,a5,1
    80000d42:	dd3c                	sw	a5,120(a0)
}
    80000d44:	60e2                	ld	ra,24(sp)
    80000d46:	6442                	ld	s0,16(sp)
    80000d48:	64a2                	ld	s1,8(sp)
    80000d4a:	6105                	addi	sp,sp,32
    80000d4c:	8082                	ret
    mycpu()->intena = old;
    80000d4e:	00001097          	auipc	ra,0x1
    80000d52:	dca080e7          	jalr	-566(ra) # 80001b18 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d56:	8085                	srli	s1,s1,0x1
    80000d58:	8885                	andi	s1,s1,1
    80000d5a:	dd64                	sw	s1,124(a0)
    80000d5c:	bfe9                	j	80000d36 <push_off+0x24>

0000000080000d5e <acquire>:
{
    80000d5e:	1101                	addi	sp,sp,-32
    80000d60:	ec06                	sd	ra,24(sp)
    80000d62:	e822                	sd	s0,16(sp)
    80000d64:	e426                	sd	s1,8(sp)
    80000d66:	1000                	addi	s0,sp,32
    80000d68:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d6a:	00000097          	auipc	ra,0x0
    80000d6e:	fa8080e7          	jalr	-88(ra) # 80000d12 <push_off>
  if(holding(lk))
    80000d72:	8526                	mv	a0,s1
    80000d74:	00000097          	auipc	ra,0x0
    80000d78:	f70080e7          	jalr	-144(ra) # 80000ce4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d7c:	4705                	li	a4,1
  if(holding(lk))
    80000d7e:	e115                	bnez	a0,80000da2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d80:	87ba                	mv	a5,a4
    80000d82:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d86:	2781                	sext.w	a5,a5
    80000d88:	ffe5                	bnez	a5,80000d80 <acquire+0x22>
  __sync_synchronize();
    80000d8a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d8e:	00001097          	auipc	ra,0x1
    80000d92:	d8a080e7          	jalr	-630(ra) # 80001b18 <mycpu>
    80000d96:	e888                	sd	a0,16(s1)
}
    80000d98:	60e2                	ld	ra,24(sp)
    80000d9a:	6442                	ld	s0,16(sp)
    80000d9c:	64a2                	ld	s1,8(sp)
    80000d9e:	6105                	addi	sp,sp,32
    80000da0:	8082                	ret
    panic("acquire");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	2fe50513          	addi	a0,a0,766 # 800080a0 <digits+0x30>
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	91c080e7          	jalr	-1764(ra) # 800006c6 <panic>

0000000080000db2 <pop_off>:

void
pop_off(void)
{
    80000db2:	1141                	addi	sp,sp,-16
    80000db4:	e406                	sd	ra,8(sp)
    80000db6:	e022                	sd	s0,0(sp)
    80000db8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dba:	00001097          	auipc	ra,0x1
    80000dbe:	d5e080e7          	jalr	-674(ra) # 80001b18 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dc2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dc6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dc8:	e78d                	bnez	a5,80000df2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dca:	5d3c                	lw	a5,120(a0)
    80000dcc:	02f05b63          	blez	a5,80000e02 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dd0:	37fd                	addiw	a5,a5,-1
    80000dd2:	0007871b          	sext.w	a4,a5
    80000dd6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dd8:	eb09                	bnez	a4,80000dea <pop_off+0x38>
    80000dda:	5d7c                	lw	a5,124(a0)
    80000ddc:	c799                	beqz	a5,80000dea <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dde:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000de2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000de6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dea:	60a2                	ld	ra,8(sp)
    80000dec:	6402                	ld	s0,0(sp)
    80000dee:	0141                	addi	sp,sp,16
    80000df0:	8082                	ret
    panic("pop_off - interruptible");
    80000df2:	00007517          	auipc	a0,0x7
    80000df6:	2b650513          	addi	a0,a0,694 # 800080a8 <digits+0x38>
    80000dfa:	00000097          	auipc	ra,0x0
    80000dfe:	8cc080e7          	jalr	-1844(ra) # 800006c6 <panic>
    panic("pop_off");
    80000e02:	00007517          	auipc	a0,0x7
    80000e06:	2be50513          	addi	a0,a0,702 # 800080c0 <digits+0x50>
    80000e0a:	00000097          	auipc	ra,0x0
    80000e0e:	8bc080e7          	jalr	-1860(ra) # 800006c6 <panic>

0000000080000e12 <release>:
{
    80000e12:	1101                	addi	sp,sp,-32
    80000e14:	ec06                	sd	ra,24(sp)
    80000e16:	e822                	sd	s0,16(sp)
    80000e18:	e426                	sd	s1,8(sp)
    80000e1a:	1000                	addi	s0,sp,32
    80000e1c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e1e:	00000097          	auipc	ra,0x0
    80000e22:	ec6080e7          	jalr	-314(ra) # 80000ce4 <holding>
    80000e26:	c115                	beqz	a0,80000e4a <release+0x38>
  lk->cpu = 0;
    80000e28:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e2c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e30:	0f50000f          	fence	iorw,ow
    80000e34:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e38:	00000097          	auipc	ra,0x0
    80000e3c:	f7a080e7          	jalr	-134(ra) # 80000db2 <pop_off>
}
    80000e40:	60e2                	ld	ra,24(sp)
    80000e42:	6442                	ld	s0,16(sp)
    80000e44:	64a2                	ld	s1,8(sp)
    80000e46:	6105                	addi	sp,sp,32
    80000e48:	8082                	ret
    panic("release");
    80000e4a:	00007517          	auipc	a0,0x7
    80000e4e:	27e50513          	addi	a0,a0,638 # 800080c8 <digits+0x58>
    80000e52:	00000097          	auipc	ra,0x0
    80000e56:	874080e7          	jalr	-1932(ra) # 800006c6 <panic>

0000000080000e5a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e60:	ca19                	beqz	a2,80000e76 <memset+0x1c>
    80000e62:	87aa                	mv	a5,a0
    80000e64:	1602                	slli	a2,a2,0x20
    80000e66:	9201                	srli	a2,a2,0x20
    80000e68:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e70:	0785                	addi	a5,a5,1
    80000e72:	fee79de3          	bne	a5,a4,80000e6c <memset+0x12>
  }
  return dst;
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret

0000000080000e7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e422                	sd	s0,8(sp)
    80000e80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e82:	ca05                	beqz	a2,80000eb2 <memcmp+0x36>
    80000e84:	fff6069b          	addiw	a3,a2,-1
    80000e88:	1682                	slli	a3,a3,0x20
    80000e8a:	9281                	srli	a3,a3,0x20
    80000e8c:	0685                	addi	a3,a3,1
    80000e8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e90:	00054783          	lbu	a5,0(a0)
    80000e94:	0005c703          	lbu	a4,0(a1)
    80000e98:	00e79863          	bne	a5,a4,80000ea8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e9c:	0505                	addi	a0,a0,1
    80000e9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ea0:	fed518e3          	bne	a0,a3,80000e90 <memcmp+0x14>
  }

  return 0;
    80000ea4:	4501                	li	a0,0
    80000ea6:	a019                	j	80000eac <memcmp+0x30>
      return *s1 - *s2;
    80000ea8:	40e7853b          	subw	a0,a5,a4
}
    80000eac:	6422                	ld	s0,8(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret
  return 0;
    80000eb2:	4501                	li	a0,0
    80000eb4:	bfe5                	j	80000eac <memcmp+0x30>

0000000080000eb6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eb6:	1141                	addi	sp,sp,-16
    80000eb8:	e422                	sd	s0,8(sp)
    80000eba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ebc:	c205                	beqz	a2,80000edc <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ebe:	02a5e263          	bltu	a1,a0,80000ee2 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ec2:	1602                	slli	a2,a2,0x20
    80000ec4:	9201                	srli	a2,a2,0x20
    80000ec6:	00c587b3          	add	a5,a1,a2
{
    80000eca:	872a                	mv	a4,a0
      *d++ = *s++;
    80000ecc:	0585                	addi	a1,a1,1
    80000ece:	0705                	addi	a4,a4,1
    80000ed0:	fff5c683          	lbu	a3,-1(a1)
    80000ed4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ed8:	fef59ae3          	bne	a1,a5,80000ecc <memmove+0x16>

  return dst;
}
    80000edc:	6422                	ld	s0,8(sp)
    80000ede:	0141                	addi	sp,sp,16
    80000ee0:	8082                	ret
  if(s < d && s + n > d){
    80000ee2:	02061693          	slli	a3,a2,0x20
    80000ee6:	9281                	srli	a3,a3,0x20
    80000ee8:	00d58733          	add	a4,a1,a3
    80000eec:	fce57be3          	bgeu	a0,a4,80000ec2 <memmove+0xc>
    d += n;
    80000ef0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ef2:	fff6079b          	addiw	a5,a2,-1
    80000ef6:	1782                	slli	a5,a5,0x20
    80000ef8:	9381                	srli	a5,a5,0x20
    80000efa:	fff7c793          	not	a5,a5
    80000efe:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f00:	177d                	addi	a4,a4,-1
    80000f02:	16fd                	addi	a3,a3,-1
    80000f04:	00074603          	lbu	a2,0(a4)
    80000f08:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f0c:	fee79ae3          	bne	a5,a4,80000f00 <memmove+0x4a>
    80000f10:	b7f1                	j	80000edc <memmove+0x26>

0000000080000f12 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f12:	1141                	addi	sp,sp,-16
    80000f14:	e406                	sd	ra,8(sp)
    80000f16:	e022                	sd	s0,0(sp)
    80000f18:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	f9c080e7          	jalr	-100(ra) # 80000eb6 <memmove>
}
    80000f22:	60a2                	ld	ra,8(sp)
    80000f24:	6402                	ld	s0,0(sp)
    80000f26:	0141                	addi	sp,sp,16
    80000f28:	8082                	ret

0000000080000f2a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f2a:	1141                	addi	sp,sp,-16
    80000f2c:	e422                	sd	s0,8(sp)
    80000f2e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f30:	ce11                	beqz	a2,80000f4c <strncmp+0x22>
    80000f32:	00054783          	lbu	a5,0(a0)
    80000f36:	cf89                	beqz	a5,80000f50 <strncmp+0x26>
    80000f38:	0005c703          	lbu	a4,0(a1)
    80000f3c:	00f71a63          	bne	a4,a5,80000f50 <strncmp+0x26>
    n--, p++, q++;
    80000f40:	367d                	addiw	a2,a2,-1
    80000f42:	0505                	addi	a0,a0,1
    80000f44:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f46:	f675                	bnez	a2,80000f32 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f48:	4501                	li	a0,0
    80000f4a:	a809                	j	80000f5c <strncmp+0x32>
    80000f4c:	4501                	li	a0,0
    80000f4e:	a039                	j	80000f5c <strncmp+0x32>
  if(n == 0)
    80000f50:	ca09                	beqz	a2,80000f62 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f52:	00054503          	lbu	a0,0(a0)
    80000f56:	0005c783          	lbu	a5,0(a1)
    80000f5a:	9d1d                	subw	a0,a0,a5
}
    80000f5c:	6422                	ld	s0,8(sp)
    80000f5e:	0141                	addi	sp,sp,16
    80000f60:	8082                	ret
    return 0;
    80000f62:	4501                	li	a0,0
    80000f64:	bfe5                	j	80000f5c <strncmp+0x32>

0000000080000f66 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f66:	1141                	addi	sp,sp,-16
    80000f68:	e422                	sd	s0,8(sp)
    80000f6a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f6c:	872a                	mv	a4,a0
    80000f6e:	8832                	mv	a6,a2
    80000f70:	367d                	addiw	a2,a2,-1
    80000f72:	01005963          	blez	a6,80000f84 <strncpy+0x1e>
    80000f76:	0705                	addi	a4,a4,1
    80000f78:	0005c783          	lbu	a5,0(a1)
    80000f7c:	fef70fa3          	sb	a5,-1(a4)
    80000f80:	0585                	addi	a1,a1,1
    80000f82:	f7f5                	bnez	a5,80000f6e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f84:	86ba                	mv	a3,a4
    80000f86:	00c05c63          	blez	a2,80000f9e <strncpy+0x38>
    *s++ = 0;
    80000f8a:	0685                	addi	a3,a3,1
    80000f8c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f90:	fff6c793          	not	a5,a3
    80000f94:	9fb9                	addw	a5,a5,a4
    80000f96:	010787bb          	addw	a5,a5,a6
    80000f9a:	fef048e3          	bgtz	a5,80000f8a <strncpy+0x24>
  return os;
}
    80000f9e:	6422                	ld	s0,8(sp)
    80000fa0:	0141                	addi	sp,sp,16
    80000fa2:	8082                	ret

0000000080000fa4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000faa:	02c05363          	blez	a2,80000fd0 <safestrcpy+0x2c>
    80000fae:	fff6069b          	addiw	a3,a2,-1
    80000fb2:	1682                	slli	a3,a3,0x20
    80000fb4:	9281                	srli	a3,a3,0x20
    80000fb6:	96ae                	add	a3,a3,a1
    80000fb8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fba:	00d58963          	beq	a1,a3,80000fcc <safestrcpy+0x28>
    80000fbe:	0585                	addi	a1,a1,1
    80000fc0:	0785                	addi	a5,a5,1
    80000fc2:	fff5c703          	lbu	a4,-1(a1)
    80000fc6:	fee78fa3          	sb	a4,-1(a5)
    80000fca:	fb65                	bnez	a4,80000fba <safestrcpy+0x16>
    ;
  *s = 0;
    80000fcc:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fd0:	6422                	ld	s0,8(sp)
    80000fd2:	0141                	addi	sp,sp,16
    80000fd4:	8082                	ret

0000000080000fd6 <strlen>:

int
strlen(const char *s)
{
    80000fd6:	1141                	addi	sp,sp,-16
    80000fd8:	e422                	sd	s0,8(sp)
    80000fda:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fdc:	00054783          	lbu	a5,0(a0)
    80000fe0:	cf91                	beqz	a5,80000ffc <strlen+0x26>
    80000fe2:	0505                	addi	a0,a0,1
    80000fe4:	87aa                	mv	a5,a0
    80000fe6:	4685                	li	a3,1
    80000fe8:	9e89                	subw	a3,a3,a0
    80000fea:	00f6853b          	addw	a0,a3,a5
    80000fee:	0785                	addi	a5,a5,1
    80000ff0:	fff7c703          	lbu	a4,-1(a5)
    80000ff4:	fb7d                	bnez	a4,80000fea <strlen+0x14>
    ;
  return n;
}
    80000ff6:	6422                	ld	s0,8(sp)
    80000ff8:	0141                	addi	sp,sp,16
    80000ffa:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ffc:	4501                	li	a0,0
    80000ffe:	bfe5                	j	80000ff6 <strlen+0x20>

0000000080001000 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001000:	1141                	addi	sp,sp,-16
    80001002:	e406                	sd	ra,8(sp)
    80001004:	e022                	sd	s0,0(sp)
    80001006:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	b00080e7          	jalr	-1280(ra) # 80001b08 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001010:	00008717          	auipc	a4,0x8
    80001014:	8d870713          	addi	a4,a4,-1832 # 800088e8 <started>
  if(cpuid() == 0){
    80001018:	c139                	beqz	a0,8000105e <main+0x5e>
    while(started == 0)
    8000101a:	431c                	lw	a5,0(a4)
    8000101c:	2781                	sext.w	a5,a5
    8000101e:	dff5                	beqz	a5,8000101a <main+0x1a>
      ;
    __sync_synchronize();
    80001020:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001024:	00001097          	auipc	ra,0x1
    80001028:	ae4080e7          	jalr	-1308(ra) # 80001b08 <cpuid>
    8000102c:	85aa                	mv	a1,a0
    8000102e:	00007517          	auipc	a0,0x7
    80001032:	0ba50513          	addi	a0,a0,186 # 800080e8 <digits+0x78>
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	6da080e7          	jalr	1754(ra) # 80000710 <printf>
    kvminithart();    // turn on paging
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	0d8080e7          	jalr	216(ra) # 80001116 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001046:	00002097          	auipc	ra,0x2
    8000104a:	860080e7          	jalr	-1952(ra) # 800028a6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000104e:	00005097          	auipc	ra,0x5
    80001052:	e42080e7          	jalr	-446(ra) # 80005e90 <plicinithart>
  }

  scheduler();        
    80001056:	00001097          	auipc	ra,0x1
    8000105a:	fd4080e7          	jalr	-44(ra) # 8000202a <scheduler>
    consoleinit();
    8000105e:	fffff097          	auipc	ra,0xfffff
    80001062:	4c6080e7          	jalr	1222(ra) # 80000524 <consoleinit>
    printfinit();
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	88a080e7          	jalr	-1910(ra) # 800008f0 <printfinit>
    printf("\n");
    8000106e:	00007517          	auipc	a0,0x7
    80001072:	08a50513          	addi	a0,a0,138 # 800080f8 <digits+0x88>
    80001076:	fffff097          	auipc	ra,0xfffff
    8000107a:	69a080e7          	jalr	1690(ra) # 80000710 <printf>
    printf("xv6 kernel is booting\n");
    8000107e:	00007517          	auipc	a0,0x7
    80001082:	05250513          	addi	a0,a0,82 # 800080d0 <digits+0x60>
    80001086:	fffff097          	auipc	ra,0xfffff
    8000108a:	68a080e7          	jalr	1674(ra) # 80000710 <printf>
    printf("\n");
    8000108e:	00007517          	auipc	a0,0x7
    80001092:	06a50513          	addi	a0,a0,106 # 800080f8 <digits+0x88>
    80001096:	fffff097          	auipc	ra,0xfffff
    8000109a:	67a080e7          	jalr	1658(ra) # 80000710 <printf>
    kinit();         // physical page allocator
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	b94080e7          	jalr	-1132(ra) # 80000c32 <kinit>
    kvminit();       // create kernel page table
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	326080e7          	jalr	806(ra) # 800013cc <kvminit>
    kvminithart();   // turn on paging
    800010ae:	00000097          	auipc	ra,0x0
    800010b2:	068080e7          	jalr	104(ra) # 80001116 <kvminithart>
    procinit();      // process table
    800010b6:	00001097          	auipc	ra,0x1
    800010ba:	99e080e7          	jalr	-1634(ra) # 80001a54 <procinit>
    trapinit();      // trap vectors
    800010be:	00001097          	auipc	ra,0x1
    800010c2:	7c0080e7          	jalr	1984(ra) # 8000287e <trapinit>
    trapinithart();  // install kernel trap vector
    800010c6:	00001097          	auipc	ra,0x1
    800010ca:	7e0080e7          	jalr	2016(ra) # 800028a6 <trapinithart>
    plicinit();      // set up interrupt controller
    800010ce:	00005097          	auipc	ra,0x5
    800010d2:	dac080e7          	jalr	-596(ra) # 80005e7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010d6:	00005097          	auipc	ra,0x5
    800010da:	dba080e7          	jalr	-582(ra) # 80005e90 <plicinithart>
    binit();         // buffer cache
    800010de:	00002097          	auipc	ra,0x2
    800010e2:	f64080e7          	jalr	-156(ra) # 80003042 <binit>
    iinit();         // inode table
    800010e6:	00002097          	auipc	ra,0x2
    800010ea:	608080e7          	jalr	1544(ra) # 800036ee <iinit>
    fileinit();      // file table
    800010ee:	00003097          	auipc	ra,0x3
    800010f2:	5a6080e7          	jalr	1446(ra) # 80004694 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010f6:	00005097          	auipc	ra,0x5
    800010fa:	ea2080e7          	jalr	-350(ra) # 80005f98 <virtio_disk_init>
    userinit();      // first user process
    800010fe:	00001097          	auipc	ra,0x1
    80001102:	d0e080e7          	jalr	-754(ra) # 80001e0c <userinit>
    __sync_synchronize();
    80001106:	0ff0000f          	fence
    started = 1;
    8000110a:	4785                	li	a5,1
    8000110c:	00007717          	auipc	a4,0x7
    80001110:	7cf72e23          	sw	a5,2012(a4) # 800088e8 <started>
    80001114:	b789                	j	80001056 <main+0x56>

0000000080001116 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001116:	1141                	addi	sp,sp,-16
    80001118:	e422                	sd	s0,8(sp)
    8000111a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000111c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001120:	00007797          	auipc	a5,0x7
    80001124:	7d07b783          	ld	a5,2000(a5) # 800088f0 <kernel_pagetable>
    80001128:	83b1                	srli	a5,a5,0xc
    8000112a:	577d                	li	a4,-1
    8000112c:	177e                	slli	a4,a4,0x3f
    8000112e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001130:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001134:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001138:	6422                	ld	s0,8(sp)
    8000113a:	0141                	addi	sp,sp,16
    8000113c:	8082                	ret

000000008000113e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000113e:	7139                	addi	sp,sp,-64
    80001140:	fc06                	sd	ra,56(sp)
    80001142:	f822                	sd	s0,48(sp)
    80001144:	f426                	sd	s1,40(sp)
    80001146:	f04a                	sd	s2,32(sp)
    80001148:	ec4e                	sd	s3,24(sp)
    8000114a:	e852                	sd	s4,16(sp)
    8000114c:	e456                	sd	s5,8(sp)
    8000114e:	e05a                	sd	s6,0(sp)
    80001150:	0080                	addi	s0,sp,64
    80001152:	84aa                	mv	s1,a0
    80001154:	89ae                	mv	s3,a1
    80001156:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001158:	57fd                	li	a5,-1
    8000115a:	83e9                	srli	a5,a5,0x1a
    8000115c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000115e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001160:	04b7f263          	bgeu	a5,a1,800011a4 <walk+0x66>
    panic("walk");
    80001164:	00007517          	auipc	a0,0x7
    80001168:	f9c50513          	addi	a0,a0,-100 # 80008100 <digits+0x90>
    8000116c:	fffff097          	auipc	ra,0xfffff
    80001170:	55a080e7          	jalr	1370(ra) # 800006c6 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001174:	060a8663          	beqz	s5,800011e0 <walk+0xa2>
    80001178:	00000097          	auipc	ra,0x0
    8000117c:	af6080e7          	jalr	-1290(ra) # 80000c6e <kalloc>
    80001180:	84aa                	mv	s1,a0
    80001182:	c529                	beqz	a0,800011cc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	cd2080e7          	jalr	-814(ra) # 80000e5a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001190:	00c4d793          	srli	a5,s1,0xc
    80001194:	07aa                	slli	a5,a5,0xa
    80001196:	0017e793          	ori	a5,a5,1
    8000119a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000119e:	3a5d                	addiw	s4,s4,-9
    800011a0:	036a0063          	beq	s4,s6,800011c0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011a4:	0149d933          	srl	s2,s3,s4
    800011a8:	1ff97913          	andi	s2,s2,511
    800011ac:	090e                	slli	s2,s2,0x3
    800011ae:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011b0:	00093483          	ld	s1,0(s2)
    800011b4:	0014f793          	andi	a5,s1,1
    800011b8:	dfd5                	beqz	a5,80001174 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011ba:	80a9                	srli	s1,s1,0xa
    800011bc:	04b2                	slli	s1,s1,0xc
    800011be:	b7c5                	j	8000119e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011c0:	00c9d513          	srli	a0,s3,0xc
    800011c4:	1ff57513          	andi	a0,a0,511
    800011c8:	050e                	slli	a0,a0,0x3
    800011ca:	9526                	add	a0,a0,s1
}
    800011cc:	70e2                	ld	ra,56(sp)
    800011ce:	7442                	ld	s0,48(sp)
    800011d0:	74a2                	ld	s1,40(sp)
    800011d2:	7902                	ld	s2,32(sp)
    800011d4:	69e2                	ld	s3,24(sp)
    800011d6:	6a42                	ld	s4,16(sp)
    800011d8:	6aa2                	ld	s5,8(sp)
    800011da:	6b02                	ld	s6,0(sp)
    800011dc:	6121                	addi	sp,sp,64
    800011de:	8082                	ret
        return 0;
    800011e0:	4501                	li	a0,0
    800011e2:	b7ed                	j	800011cc <walk+0x8e>

00000000800011e4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011e4:	57fd                	li	a5,-1
    800011e6:	83e9                	srli	a5,a5,0x1a
    800011e8:	00b7f463          	bgeu	a5,a1,800011f0 <walkaddr+0xc>
    return 0;
    800011ec:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011ee:	8082                	ret
{
    800011f0:	1141                	addi	sp,sp,-16
    800011f2:	e406                	sd	ra,8(sp)
    800011f4:	e022                	sd	s0,0(sp)
    800011f6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011f8:	4601                	li	a2,0
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	f44080e7          	jalr	-188(ra) # 8000113e <walk>
  if(pte == 0)
    80001202:	c105                	beqz	a0,80001222 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001204:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001206:	0117f693          	andi	a3,a5,17
    8000120a:	4745                	li	a4,17
    return 0;
    8000120c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000120e:	00e68663          	beq	a3,a4,8000121a <walkaddr+0x36>
}
    80001212:	60a2                	ld	ra,8(sp)
    80001214:	6402                	ld	s0,0(sp)
    80001216:	0141                	addi	sp,sp,16
    80001218:	8082                	ret
  pa = PTE2PA(*pte);
    8000121a:	00a7d513          	srli	a0,a5,0xa
    8000121e:	0532                	slli	a0,a0,0xc
  return pa;
    80001220:	bfcd                	j	80001212 <walkaddr+0x2e>
    return 0;
    80001222:	4501                	li	a0,0
    80001224:	b7fd                	j	80001212 <walkaddr+0x2e>

0000000080001226 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001226:	715d                	addi	sp,sp,-80
    80001228:	e486                	sd	ra,72(sp)
    8000122a:	e0a2                	sd	s0,64(sp)
    8000122c:	fc26                	sd	s1,56(sp)
    8000122e:	f84a                	sd	s2,48(sp)
    80001230:	f44e                	sd	s3,40(sp)
    80001232:	f052                	sd	s4,32(sp)
    80001234:	ec56                	sd	s5,24(sp)
    80001236:	e85a                	sd	s6,16(sp)
    80001238:	e45e                	sd	s7,8(sp)
    8000123a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000123c:	c639                	beqz	a2,8000128a <mappages+0x64>
    8000123e:	8aaa                	mv	s5,a0
    80001240:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001242:	77fd                	lui	a5,0xfffff
    80001244:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001248:	15fd                	addi	a1,a1,-1
    8000124a:	00c589b3          	add	s3,a1,a2
    8000124e:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001252:	8952                	mv	s2,s4
    80001254:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001258:	6b85                	lui	s7,0x1
    8000125a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000125e:	4605                	li	a2,1
    80001260:	85ca                	mv	a1,s2
    80001262:	8556                	mv	a0,s5
    80001264:	00000097          	auipc	ra,0x0
    80001268:	eda080e7          	jalr	-294(ra) # 8000113e <walk>
    8000126c:	cd1d                	beqz	a0,800012aa <mappages+0x84>
    if(*pte & PTE_V)
    8000126e:	611c                	ld	a5,0(a0)
    80001270:	8b85                	andi	a5,a5,1
    80001272:	e785                	bnez	a5,8000129a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001274:	80b1                	srli	s1,s1,0xc
    80001276:	04aa                	slli	s1,s1,0xa
    80001278:	0164e4b3          	or	s1,s1,s6
    8000127c:	0014e493          	ori	s1,s1,1
    80001280:	e104                	sd	s1,0(a0)
    if(a == last)
    80001282:	05390063          	beq	s2,s3,800012c2 <mappages+0x9c>
    a += PGSIZE;
    80001286:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001288:	bfc9                	j	8000125a <mappages+0x34>
    panic("mappages: size");
    8000128a:	00007517          	auipc	a0,0x7
    8000128e:	e7e50513          	addi	a0,a0,-386 # 80008108 <digits+0x98>
    80001292:	fffff097          	auipc	ra,0xfffff
    80001296:	434080e7          	jalr	1076(ra) # 800006c6 <panic>
      panic("mappages: remap");
    8000129a:	00007517          	auipc	a0,0x7
    8000129e:	e7e50513          	addi	a0,a0,-386 # 80008118 <digits+0xa8>
    800012a2:	fffff097          	auipc	ra,0xfffff
    800012a6:	424080e7          	jalr	1060(ra) # 800006c6 <panic>
      return -1;
    800012aa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012ac:	60a6                	ld	ra,72(sp)
    800012ae:	6406                	ld	s0,64(sp)
    800012b0:	74e2                	ld	s1,56(sp)
    800012b2:	7942                	ld	s2,48(sp)
    800012b4:	79a2                	ld	s3,40(sp)
    800012b6:	7a02                	ld	s4,32(sp)
    800012b8:	6ae2                	ld	s5,24(sp)
    800012ba:	6b42                	ld	s6,16(sp)
    800012bc:	6ba2                	ld	s7,8(sp)
    800012be:	6161                	addi	sp,sp,80
    800012c0:	8082                	ret
  return 0;
    800012c2:	4501                	li	a0,0
    800012c4:	b7e5                	j	800012ac <mappages+0x86>

00000000800012c6 <kvmmap>:
{
    800012c6:	1141                	addi	sp,sp,-16
    800012c8:	e406                	sd	ra,8(sp)
    800012ca:	e022                	sd	s0,0(sp)
    800012cc:	0800                	addi	s0,sp,16
    800012ce:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012d0:	86b2                	mv	a3,a2
    800012d2:	863e                	mv	a2,a5
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f52080e7          	jalr	-174(ra) # 80001226 <mappages>
    800012dc:	e509                	bnez	a0,800012e6 <kvmmap+0x20>
}
    800012de:	60a2                	ld	ra,8(sp)
    800012e0:	6402                	ld	s0,0(sp)
    800012e2:	0141                	addi	sp,sp,16
    800012e4:	8082                	ret
    panic("kvmmap");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xb8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	3d8080e7          	jalr	984(ra) # 800006c6 <panic>

00000000800012f6 <kvmmake>:
{
    800012f6:	1101                	addi	sp,sp,-32
    800012f8:	ec06                	sd	ra,24(sp)
    800012fa:	e822                	sd	s0,16(sp)
    800012fc:	e426                	sd	s1,8(sp)
    800012fe:	e04a                	sd	s2,0(sp)
    80001300:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001302:	00000097          	auipc	ra,0x0
    80001306:	96c080e7          	jalr	-1684(ra) # 80000c6e <kalloc>
    8000130a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000130c:	6605                	lui	a2,0x1
    8000130e:	4581                	li	a1,0
    80001310:	00000097          	auipc	ra,0x0
    80001314:	b4a080e7          	jalr	-1206(ra) # 80000e5a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001318:	4719                	li	a4,6
    8000131a:	6685                	lui	a3,0x1
    8000131c:	10000637          	lui	a2,0x10000
    80001320:	100005b7          	lui	a1,0x10000
    80001324:	8526                	mv	a0,s1
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	fa0080e7          	jalr	-96(ra) # 800012c6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000132e:	4719                	li	a4,6
    80001330:	6685                	lui	a3,0x1
    80001332:	10001637          	lui	a2,0x10001
    80001336:	100015b7          	lui	a1,0x10001
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	f8a080e7          	jalr	-118(ra) # 800012c6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001344:	4719                	li	a4,6
    80001346:	004006b7          	lui	a3,0x400
    8000134a:	0c000637          	lui	a2,0xc000
    8000134e:	0c0005b7          	lui	a1,0xc000
    80001352:	8526                	mv	a0,s1
    80001354:	00000097          	auipc	ra,0x0
    80001358:	f72080e7          	jalr	-142(ra) # 800012c6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000135c:	00007917          	auipc	s2,0x7
    80001360:	ca490913          	addi	s2,s2,-860 # 80008000 <etext>
    80001364:	4729                	li	a4,10
    80001366:	80007697          	auipc	a3,0x80007
    8000136a:	c9a68693          	addi	a3,a3,-870 # 8000 <_entry-0x7fff8000>
    8000136e:	4605                	li	a2,1
    80001370:	067e                	slli	a2,a2,0x1f
    80001372:	85b2                	mv	a1,a2
    80001374:	8526                	mv	a0,s1
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	f50080e7          	jalr	-176(ra) # 800012c6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000137e:	4719                	li	a4,6
    80001380:	46c5                	li	a3,17
    80001382:	06ee                	slli	a3,a3,0x1b
    80001384:	412686b3          	sub	a3,a3,s2
    80001388:	864a                	mv	a2,s2
    8000138a:	85ca                	mv	a1,s2
    8000138c:	8526                	mv	a0,s1
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	f38080e7          	jalr	-200(ra) # 800012c6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001396:	4729                	li	a4,10
    80001398:	6685                	lui	a3,0x1
    8000139a:	00006617          	auipc	a2,0x6
    8000139e:	c6660613          	addi	a2,a2,-922 # 80007000 <_trampoline>
    800013a2:	040005b7          	lui	a1,0x4000
    800013a6:	15fd                	addi	a1,a1,-1
    800013a8:	05b2                	slli	a1,a1,0xc
    800013aa:	8526                	mv	a0,s1
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	f1a080e7          	jalr	-230(ra) # 800012c6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013b4:	8526                	mv	a0,s1
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	608080e7          	jalr	1544(ra) # 800019be <proc_mapstacks>
}
    800013be:	8526                	mv	a0,s1
    800013c0:	60e2                	ld	ra,24(sp)
    800013c2:	6442                	ld	s0,16(sp)
    800013c4:	64a2                	ld	s1,8(sp)
    800013c6:	6902                	ld	s2,0(sp)
    800013c8:	6105                	addi	sp,sp,32
    800013ca:	8082                	ret

00000000800013cc <kvminit>:
{
    800013cc:	1141                	addi	sp,sp,-16
    800013ce:	e406                	sd	ra,8(sp)
    800013d0:	e022                	sd	s0,0(sp)
    800013d2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	f22080e7          	jalr	-222(ra) # 800012f6 <kvmmake>
    800013dc:	00007797          	auipc	a5,0x7
    800013e0:	50a7ba23          	sd	a0,1300(a5) # 800088f0 <kernel_pagetable>
}
    800013e4:	60a2                	ld	ra,8(sp)
    800013e6:	6402                	ld	s0,0(sp)
    800013e8:	0141                	addi	sp,sp,16
    800013ea:	8082                	ret

00000000800013ec <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013ec:	715d                	addi	sp,sp,-80
    800013ee:	e486                	sd	ra,72(sp)
    800013f0:	e0a2                	sd	s0,64(sp)
    800013f2:	fc26                	sd	s1,56(sp)
    800013f4:	f84a                	sd	s2,48(sp)
    800013f6:	f44e                	sd	s3,40(sp)
    800013f8:	f052                	sd	s4,32(sp)
    800013fa:	ec56                	sd	s5,24(sp)
    800013fc:	e85a                	sd	s6,16(sp)
    800013fe:	e45e                	sd	s7,8(sp)
    80001400:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001402:	03459793          	slli	a5,a1,0x34
    80001406:	e795                	bnez	a5,80001432 <uvmunmap+0x46>
    80001408:	8a2a                	mv	s4,a0
    8000140a:	892e                	mv	s2,a1
    8000140c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000140e:	0632                	slli	a2,a2,0xc
    80001410:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001414:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001416:	6b05                	lui	s6,0x1
    80001418:	0735e263          	bltu	a1,s3,8000147c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000141c:	60a6                	ld	ra,72(sp)
    8000141e:	6406                	ld	s0,64(sp)
    80001420:	74e2                	ld	s1,56(sp)
    80001422:	7942                	ld	s2,48(sp)
    80001424:	79a2                	ld	s3,40(sp)
    80001426:	7a02                	ld	s4,32(sp)
    80001428:	6ae2                	ld	s5,24(sp)
    8000142a:	6b42                	ld	s6,16(sp)
    8000142c:	6ba2                	ld	s7,8(sp)
    8000142e:	6161                	addi	sp,sp,80
    80001430:	8082                	ret
    panic("uvmunmap: not aligned");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	cfe50513          	addi	a0,a0,-770 # 80008130 <digits+0xc0>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	28c080e7          	jalr	652(ra) # 800006c6 <panic>
      panic("uvmunmap: walk");
    80001442:	00007517          	auipc	a0,0x7
    80001446:	d0650513          	addi	a0,a0,-762 # 80008148 <digits+0xd8>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	27c080e7          	jalr	636(ra) # 800006c6 <panic>
      panic("uvmunmap: not mapped");
    80001452:	00007517          	auipc	a0,0x7
    80001456:	d0650513          	addi	a0,a0,-762 # 80008158 <digits+0xe8>
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	26c080e7          	jalr	620(ra) # 800006c6 <panic>
      panic("uvmunmap: not a leaf");
    80001462:	00007517          	auipc	a0,0x7
    80001466:	d0e50513          	addi	a0,a0,-754 # 80008170 <digits+0x100>
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	25c080e7          	jalr	604(ra) # 800006c6 <panic>
    *pte = 0;
    80001472:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001476:	995a                	add	s2,s2,s6
    80001478:	fb3972e3          	bgeu	s2,s3,8000141c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000147c:	4601                	li	a2,0
    8000147e:	85ca                	mv	a1,s2
    80001480:	8552                	mv	a0,s4
    80001482:	00000097          	auipc	ra,0x0
    80001486:	cbc080e7          	jalr	-836(ra) # 8000113e <walk>
    8000148a:	84aa                	mv	s1,a0
    8000148c:	d95d                	beqz	a0,80001442 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000148e:	6108                	ld	a0,0(a0)
    80001490:	00157793          	andi	a5,a0,1
    80001494:	dfdd                	beqz	a5,80001452 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001496:	3ff57793          	andi	a5,a0,1023
    8000149a:	fd7784e3          	beq	a5,s7,80001462 <uvmunmap+0x76>
    if(do_free){
    8000149e:	fc0a8ae3          	beqz	s5,80001472 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014a2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014a4:	0532                	slli	a0,a0,0xc
    800014a6:	fffff097          	auipc	ra,0xfffff
    800014aa:	6cc080e7          	jalr	1740(ra) # 80000b72 <kfree>
    800014ae:	b7d1                	j	80001472 <uvmunmap+0x86>

00000000800014b0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014b0:	1101                	addi	sp,sp,-32
    800014b2:	ec06                	sd	ra,24(sp)
    800014b4:	e822                	sd	s0,16(sp)
    800014b6:	e426                	sd	s1,8(sp)
    800014b8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	7b4080e7          	jalr	1972(ra) # 80000c6e <kalloc>
    800014c2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014c4:	c519                	beqz	a0,800014d2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	990080e7          	jalr	-1648(ra) # 80000e5a <memset>
  return pagetable;
}
    800014d2:	8526                	mv	a0,s1
    800014d4:	60e2                	ld	ra,24(sp)
    800014d6:	6442                	ld	s0,16(sp)
    800014d8:	64a2                	ld	s1,8(sp)
    800014da:	6105                	addi	sp,sp,32
    800014dc:	8082                	ret

00000000800014de <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014ee:	6785                	lui	a5,0x1
    800014f0:	04f67863          	bgeu	a2,a5,80001540 <uvmfirst+0x62>
    800014f4:	8a2a                	mv	s4,a0
    800014f6:	89ae                	mv	s3,a1
    800014f8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	774080e7          	jalr	1908(ra) # 80000c6e <kalloc>
    80001502:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	952080e7          	jalr	-1710(ra) # 80000e5a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001510:	4779                	li	a4,30
    80001512:	86ca                	mv	a3,s2
    80001514:	6605                	lui	a2,0x1
    80001516:	4581                	li	a1,0
    80001518:	8552                	mv	a0,s4
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	d0c080e7          	jalr	-756(ra) # 80001226 <mappages>
  memmove(mem, src, sz);
    80001522:	8626                	mv	a2,s1
    80001524:	85ce                	mv	a1,s3
    80001526:	854a                	mv	a0,s2
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	98e080e7          	jalr	-1650(ra) # 80000eb6 <memmove>
}
    80001530:	70a2                	ld	ra,40(sp)
    80001532:	7402                	ld	s0,32(sp)
    80001534:	64e2                	ld	s1,24(sp)
    80001536:	6942                	ld	s2,16(sp)
    80001538:	69a2                	ld	s3,8(sp)
    8000153a:	6a02                	ld	s4,0(sp)
    8000153c:	6145                	addi	sp,sp,48
    8000153e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001540:	00007517          	auipc	a0,0x7
    80001544:	c4850513          	addi	a0,a0,-952 # 80008188 <digits+0x118>
    80001548:	fffff097          	auipc	ra,0xfffff
    8000154c:	17e080e7          	jalr	382(ra) # 800006c6 <panic>

0000000080001550 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001550:	1101                	addi	sp,sp,-32
    80001552:	ec06                	sd	ra,24(sp)
    80001554:	e822                	sd	s0,16(sp)
    80001556:	e426                	sd	s1,8(sp)
    80001558:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000155a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000155c:	00b67d63          	bgeu	a2,a1,80001576 <uvmdealloc+0x26>
    80001560:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001562:	6785                	lui	a5,0x1
    80001564:	17fd                	addi	a5,a5,-1
    80001566:	00f60733          	add	a4,a2,a5
    8000156a:	767d                	lui	a2,0xfffff
    8000156c:	8f71                	and	a4,a4,a2
    8000156e:	97ae                	add	a5,a5,a1
    80001570:	8ff1                	and	a5,a5,a2
    80001572:	00f76863          	bltu	a4,a5,80001582 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001576:	8526                	mv	a0,s1
    80001578:	60e2                	ld	ra,24(sp)
    8000157a:	6442                	ld	s0,16(sp)
    8000157c:	64a2                	ld	s1,8(sp)
    8000157e:	6105                	addi	sp,sp,32
    80001580:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001582:	8f99                	sub	a5,a5,a4
    80001584:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001586:	4685                	li	a3,1
    80001588:	0007861b          	sext.w	a2,a5
    8000158c:	85ba                	mv	a1,a4
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	e5e080e7          	jalr	-418(ra) # 800013ec <uvmunmap>
    80001596:	b7c5                	j	80001576 <uvmdealloc+0x26>

0000000080001598 <uvmalloc>:
  if(newsz < oldsz)
    80001598:	0ab66563          	bltu	a2,a1,80001642 <uvmalloc+0xaa>
{
    8000159c:	7139                	addi	sp,sp,-64
    8000159e:	fc06                	sd	ra,56(sp)
    800015a0:	f822                	sd	s0,48(sp)
    800015a2:	f426                	sd	s1,40(sp)
    800015a4:	f04a                	sd	s2,32(sp)
    800015a6:	ec4e                	sd	s3,24(sp)
    800015a8:	e852                	sd	s4,16(sp)
    800015aa:	e456                	sd	s5,8(sp)
    800015ac:	e05a                	sd	s6,0(sp)
    800015ae:	0080                	addi	s0,sp,64
    800015b0:	8aaa                	mv	s5,a0
    800015b2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015b4:	6985                	lui	s3,0x1
    800015b6:	19fd                	addi	s3,s3,-1
    800015b8:	95ce                	add	a1,a1,s3
    800015ba:	79fd                	lui	s3,0xfffff
    800015bc:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015c0:	08c9f363          	bgeu	s3,a2,80001646 <uvmalloc+0xae>
    800015c4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015c6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	6a4080e7          	jalr	1700(ra) # 80000c6e <kalloc>
    800015d2:	84aa                	mv	s1,a0
    if(mem == 0){
    800015d4:	c51d                	beqz	a0,80001602 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015d6:	6605                	lui	a2,0x1
    800015d8:	4581                	li	a1,0
    800015da:	00000097          	auipc	ra,0x0
    800015de:	880080e7          	jalr	-1920(ra) # 80000e5a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015e2:	875a                	mv	a4,s6
    800015e4:	86a6                	mv	a3,s1
    800015e6:	6605                	lui	a2,0x1
    800015e8:	85ca                	mv	a1,s2
    800015ea:	8556                	mv	a0,s5
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	c3a080e7          	jalr	-966(ra) # 80001226 <mappages>
    800015f4:	e90d                	bnez	a0,80001626 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015f6:	6785                	lui	a5,0x1
    800015f8:	993e                	add	s2,s2,a5
    800015fa:	fd4968e3          	bltu	s2,s4,800015ca <uvmalloc+0x32>
  return newsz;
    800015fe:	8552                	mv	a0,s4
    80001600:	a809                	j	80001612 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001602:	864e                	mv	a2,s3
    80001604:	85ca                	mv	a1,s2
    80001606:	8556                	mv	a0,s5
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	f48080e7          	jalr	-184(ra) # 80001550 <uvmdealloc>
      return 0;
    80001610:	4501                	li	a0,0
}
    80001612:	70e2                	ld	ra,56(sp)
    80001614:	7442                	ld	s0,48(sp)
    80001616:	74a2                	ld	s1,40(sp)
    80001618:	7902                	ld	s2,32(sp)
    8000161a:	69e2                	ld	s3,24(sp)
    8000161c:	6a42                	ld	s4,16(sp)
    8000161e:	6aa2                	ld	s5,8(sp)
    80001620:	6b02                	ld	s6,0(sp)
    80001622:	6121                	addi	sp,sp,64
    80001624:	8082                	ret
      kfree(mem);
    80001626:	8526                	mv	a0,s1
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	54a080e7          	jalr	1354(ra) # 80000b72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001630:	864e                	mv	a2,s3
    80001632:	85ca                	mv	a1,s2
    80001634:	8556                	mv	a0,s5
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	f1a080e7          	jalr	-230(ra) # 80001550 <uvmdealloc>
      return 0;
    8000163e:	4501                	li	a0,0
    80001640:	bfc9                	j	80001612 <uvmalloc+0x7a>
    return oldsz;
    80001642:	852e                	mv	a0,a1
}
    80001644:	8082                	ret
  return newsz;
    80001646:	8532                	mv	a0,a2
    80001648:	b7e9                	j	80001612 <uvmalloc+0x7a>

000000008000164a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000164a:	7179                	addi	sp,sp,-48
    8000164c:	f406                	sd	ra,40(sp)
    8000164e:	f022                	sd	s0,32(sp)
    80001650:	ec26                	sd	s1,24(sp)
    80001652:	e84a                	sd	s2,16(sp)
    80001654:	e44e                	sd	s3,8(sp)
    80001656:	e052                	sd	s4,0(sp)
    80001658:	1800                	addi	s0,sp,48
    8000165a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000165c:	84aa                	mv	s1,a0
    8000165e:	6905                	lui	s2,0x1
    80001660:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001662:	4985                	li	s3,1
    80001664:	a821                	j	8000167c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001666:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001668:	0532                	slli	a0,a0,0xc
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	fe0080e7          	jalr	-32(ra) # 8000164a <freewalk>
      pagetable[i] = 0;
    80001672:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001676:	04a1                	addi	s1,s1,8
    80001678:	03248163          	beq	s1,s2,8000169a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000167c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000167e:	00f57793          	andi	a5,a0,15
    80001682:	ff3782e3          	beq	a5,s3,80001666 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001686:	8905                	andi	a0,a0,1
    80001688:	d57d                	beqz	a0,80001676 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000168a:	00007517          	auipc	a0,0x7
    8000168e:	b1e50513          	addi	a0,a0,-1250 # 800081a8 <digits+0x138>
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	034080e7          	jalr	52(ra) # 800006c6 <panic>
    }
  }
  kfree((void*)pagetable);
    8000169a:	8552                	mv	a0,s4
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	4d6080e7          	jalr	1238(ra) # 80000b72 <kfree>
}
    800016a4:	70a2                	ld	ra,40(sp)
    800016a6:	7402                	ld	s0,32(sp)
    800016a8:	64e2                	ld	s1,24(sp)
    800016aa:	6942                	ld	s2,16(sp)
    800016ac:	69a2                	ld	s3,8(sp)
    800016ae:	6a02                	ld	s4,0(sp)
    800016b0:	6145                	addi	sp,sp,48
    800016b2:	8082                	ret

00000000800016b4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016b4:	1101                	addi	sp,sp,-32
    800016b6:	ec06                	sd	ra,24(sp)
    800016b8:	e822                	sd	s0,16(sp)
    800016ba:	e426                	sd	s1,8(sp)
    800016bc:	1000                	addi	s0,sp,32
    800016be:	84aa                	mv	s1,a0
  if(sz > 0)
    800016c0:	e999                	bnez	a1,800016d6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016c2:	8526                	mv	a0,s1
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	f86080e7          	jalr	-122(ra) # 8000164a <freewalk>
}
    800016cc:	60e2                	ld	ra,24(sp)
    800016ce:	6442                	ld	s0,16(sp)
    800016d0:	64a2                	ld	s1,8(sp)
    800016d2:	6105                	addi	sp,sp,32
    800016d4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016d6:	6605                	lui	a2,0x1
    800016d8:	167d                	addi	a2,a2,-1
    800016da:	962e                	add	a2,a2,a1
    800016dc:	4685                	li	a3,1
    800016de:	8231                	srli	a2,a2,0xc
    800016e0:	4581                	li	a1,0
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	d0a080e7          	jalr	-758(ra) # 800013ec <uvmunmap>
    800016ea:	bfe1                	j	800016c2 <uvmfree+0xe>

00000000800016ec <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016ec:	c679                	beqz	a2,800017ba <uvmcopy+0xce>
{
    800016ee:	715d                	addi	sp,sp,-80
    800016f0:	e486                	sd	ra,72(sp)
    800016f2:	e0a2                	sd	s0,64(sp)
    800016f4:	fc26                	sd	s1,56(sp)
    800016f6:	f84a                	sd	s2,48(sp)
    800016f8:	f44e                	sd	s3,40(sp)
    800016fa:	f052                	sd	s4,32(sp)
    800016fc:	ec56                	sd	s5,24(sp)
    800016fe:	e85a                	sd	s6,16(sp)
    80001700:	e45e                	sd	s7,8(sp)
    80001702:	0880                	addi	s0,sp,80
    80001704:	8b2a                	mv	s6,a0
    80001706:	8aae                	mv	s5,a1
    80001708:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000170a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000170c:	4601                	li	a2,0
    8000170e:	85ce                	mv	a1,s3
    80001710:	855a                	mv	a0,s6
    80001712:	00000097          	auipc	ra,0x0
    80001716:	a2c080e7          	jalr	-1492(ra) # 8000113e <walk>
    8000171a:	c531                	beqz	a0,80001766 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000171c:	6118                	ld	a4,0(a0)
    8000171e:	00177793          	andi	a5,a4,1
    80001722:	cbb1                	beqz	a5,80001776 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001724:	00a75593          	srli	a1,a4,0xa
    80001728:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000172c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001730:	fffff097          	auipc	ra,0xfffff
    80001734:	53e080e7          	jalr	1342(ra) # 80000c6e <kalloc>
    80001738:	892a                	mv	s2,a0
    8000173a:	c939                	beqz	a0,80001790 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000173c:	6605                	lui	a2,0x1
    8000173e:	85de                	mv	a1,s7
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	776080e7          	jalr	1910(ra) # 80000eb6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001748:	8726                	mv	a4,s1
    8000174a:	86ca                	mv	a3,s2
    8000174c:	6605                	lui	a2,0x1
    8000174e:	85ce                	mv	a1,s3
    80001750:	8556                	mv	a0,s5
    80001752:	00000097          	auipc	ra,0x0
    80001756:	ad4080e7          	jalr	-1324(ra) # 80001226 <mappages>
    8000175a:	e515                	bnez	a0,80001786 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000175c:	6785                	lui	a5,0x1
    8000175e:	99be                	add	s3,s3,a5
    80001760:	fb49e6e3          	bltu	s3,s4,8000170c <uvmcopy+0x20>
    80001764:	a081                	j	800017a4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001766:	00007517          	auipc	a0,0x7
    8000176a:	a5250513          	addi	a0,a0,-1454 # 800081b8 <digits+0x148>
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	f58080e7          	jalr	-168(ra) # 800006c6 <panic>
      panic("uvmcopy: page not present");
    80001776:	00007517          	auipc	a0,0x7
    8000177a:	a6250513          	addi	a0,a0,-1438 # 800081d8 <digits+0x168>
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	f48080e7          	jalr	-184(ra) # 800006c6 <panic>
      kfree(mem);
    80001786:	854a                	mv	a0,s2
    80001788:	fffff097          	auipc	ra,0xfffff
    8000178c:	3ea080e7          	jalr	1002(ra) # 80000b72 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001790:	4685                	li	a3,1
    80001792:	00c9d613          	srli	a2,s3,0xc
    80001796:	4581                	li	a1,0
    80001798:	8556                	mv	a0,s5
    8000179a:	00000097          	auipc	ra,0x0
    8000179e:	c52080e7          	jalr	-942(ra) # 800013ec <uvmunmap>
  return -1;
    800017a2:	557d                	li	a0,-1
}
    800017a4:	60a6                	ld	ra,72(sp)
    800017a6:	6406                	ld	s0,64(sp)
    800017a8:	74e2                	ld	s1,56(sp)
    800017aa:	7942                	ld	s2,48(sp)
    800017ac:	79a2                	ld	s3,40(sp)
    800017ae:	7a02                	ld	s4,32(sp)
    800017b0:	6ae2                	ld	s5,24(sp)
    800017b2:	6b42                	ld	s6,16(sp)
    800017b4:	6ba2                	ld	s7,8(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret
  return 0;
    800017ba:	4501                	li	a0,0
}
    800017bc:	8082                	ret

00000000800017be <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017be:	1141                	addi	sp,sp,-16
    800017c0:	e406                	sd	ra,8(sp)
    800017c2:	e022                	sd	s0,0(sp)
    800017c4:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017c6:	4601                	li	a2,0
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	976080e7          	jalr	-1674(ra) # 8000113e <walk>
  if(pte == 0)
    800017d0:	c901                	beqz	a0,800017e0 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017d2:	611c                	ld	a5,0(a0)
    800017d4:	9bbd                	andi	a5,a5,-17
    800017d6:	e11c                	sd	a5,0(a0)
}
    800017d8:	60a2                	ld	ra,8(sp)
    800017da:	6402                	ld	s0,0(sp)
    800017dc:	0141                	addi	sp,sp,16
    800017de:	8082                	ret
    panic("uvmclear");
    800017e0:	00007517          	auipc	a0,0x7
    800017e4:	a1850513          	addi	a0,a0,-1512 # 800081f8 <digits+0x188>
    800017e8:	fffff097          	auipc	ra,0xfffff
    800017ec:	ede080e7          	jalr	-290(ra) # 800006c6 <panic>

00000000800017f0 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017f0:	c6bd                	beqz	a3,8000185e <copyout+0x6e>
{
    800017f2:	715d                	addi	sp,sp,-80
    800017f4:	e486                	sd	ra,72(sp)
    800017f6:	e0a2                	sd	s0,64(sp)
    800017f8:	fc26                	sd	s1,56(sp)
    800017fa:	f84a                	sd	s2,48(sp)
    800017fc:	f44e                	sd	s3,40(sp)
    800017fe:	f052                	sd	s4,32(sp)
    80001800:	ec56                	sd	s5,24(sp)
    80001802:	e85a                	sd	s6,16(sp)
    80001804:	e45e                	sd	s7,8(sp)
    80001806:	e062                	sd	s8,0(sp)
    80001808:	0880                	addi	s0,sp,80
    8000180a:	8b2a                	mv	s6,a0
    8000180c:	8c2e                	mv	s8,a1
    8000180e:	8a32                	mv	s4,a2
    80001810:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001812:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001814:	6a85                	lui	s5,0x1
    80001816:	a015                	j	8000183a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001818:	9562                	add	a0,a0,s8
    8000181a:	0004861b          	sext.w	a2,s1
    8000181e:	85d2                	mv	a1,s4
    80001820:	41250533          	sub	a0,a0,s2
    80001824:	fffff097          	auipc	ra,0xfffff
    80001828:	692080e7          	jalr	1682(ra) # 80000eb6 <memmove>

    len -= n;
    8000182c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001830:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001832:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001836:	02098263          	beqz	s3,8000185a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000183a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000183e:	85ca                	mv	a1,s2
    80001840:	855a                	mv	a0,s6
    80001842:	00000097          	auipc	ra,0x0
    80001846:	9a2080e7          	jalr	-1630(ra) # 800011e4 <walkaddr>
    if(pa0 == 0)
    8000184a:	cd01                	beqz	a0,80001862 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000184c:	418904b3          	sub	s1,s2,s8
    80001850:	94d6                	add	s1,s1,s5
    if(n > len)
    80001852:	fc99f3e3          	bgeu	s3,s1,80001818 <copyout+0x28>
    80001856:	84ce                	mv	s1,s3
    80001858:	b7c1                	j	80001818 <copyout+0x28>
  }
  return 0;
    8000185a:	4501                	li	a0,0
    8000185c:	a021                	j	80001864 <copyout+0x74>
    8000185e:	4501                	li	a0,0
}
    80001860:	8082                	ret
      return -1;
    80001862:	557d                	li	a0,-1
}
    80001864:	60a6                	ld	ra,72(sp)
    80001866:	6406                	ld	s0,64(sp)
    80001868:	74e2                	ld	s1,56(sp)
    8000186a:	7942                	ld	s2,48(sp)
    8000186c:	79a2                	ld	s3,40(sp)
    8000186e:	7a02                	ld	s4,32(sp)
    80001870:	6ae2                	ld	s5,24(sp)
    80001872:	6b42                	ld	s6,16(sp)
    80001874:	6ba2                	ld	s7,8(sp)
    80001876:	6c02                	ld	s8,0(sp)
    80001878:	6161                	addi	sp,sp,80
    8000187a:	8082                	ret

000000008000187c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000187c:	caa5                	beqz	a3,800018ec <copyin+0x70>
{
    8000187e:	715d                	addi	sp,sp,-80
    80001880:	e486                	sd	ra,72(sp)
    80001882:	e0a2                	sd	s0,64(sp)
    80001884:	fc26                	sd	s1,56(sp)
    80001886:	f84a                	sd	s2,48(sp)
    80001888:	f44e                	sd	s3,40(sp)
    8000188a:	f052                	sd	s4,32(sp)
    8000188c:	ec56                	sd	s5,24(sp)
    8000188e:	e85a                	sd	s6,16(sp)
    80001890:	e45e                	sd	s7,8(sp)
    80001892:	e062                	sd	s8,0(sp)
    80001894:	0880                	addi	s0,sp,80
    80001896:	8b2a                	mv	s6,a0
    80001898:	8a2e                	mv	s4,a1
    8000189a:	8c32                	mv	s8,a2
    8000189c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000189e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018a0:	6a85                	lui	s5,0x1
    800018a2:	a01d                	j	800018c8 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018a4:	018505b3          	add	a1,a0,s8
    800018a8:	0004861b          	sext.w	a2,s1
    800018ac:	412585b3          	sub	a1,a1,s2
    800018b0:	8552                	mv	a0,s4
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	604080e7          	jalr	1540(ra) # 80000eb6 <memmove>

    len -= n;
    800018ba:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018be:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018c0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018c4:	02098263          	beqz	s3,800018e8 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800018c8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018cc:	85ca                	mv	a1,s2
    800018ce:	855a                	mv	a0,s6
    800018d0:	00000097          	auipc	ra,0x0
    800018d4:	914080e7          	jalr	-1772(ra) # 800011e4 <walkaddr>
    if(pa0 == 0)
    800018d8:	cd01                	beqz	a0,800018f0 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018da:	418904b3          	sub	s1,s2,s8
    800018de:	94d6                	add	s1,s1,s5
    if(n > len)
    800018e0:	fc99f2e3          	bgeu	s3,s1,800018a4 <copyin+0x28>
    800018e4:	84ce                	mv	s1,s3
    800018e6:	bf7d                	j	800018a4 <copyin+0x28>
  }
  return 0;
    800018e8:	4501                	li	a0,0
    800018ea:	a021                	j	800018f2 <copyin+0x76>
    800018ec:	4501                	li	a0,0
}
    800018ee:	8082                	ret
      return -1;
    800018f0:	557d                	li	a0,-1
}
    800018f2:	60a6                	ld	ra,72(sp)
    800018f4:	6406                	ld	s0,64(sp)
    800018f6:	74e2                	ld	s1,56(sp)
    800018f8:	7942                	ld	s2,48(sp)
    800018fa:	79a2                	ld	s3,40(sp)
    800018fc:	7a02                	ld	s4,32(sp)
    800018fe:	6ae2                	ld	s5,24(sp)
    80001900:	6b42                	ld	s6,16(sp)
    80001902:	6ba2                	ld	s7,8(sp)
    80001904:	6c02                	ld	s8,0(sp)
    80001906:	6161                	addi	sp,sp,80
    80001908:	8082                	ret

000000008000190a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000190a:	c6c5                	beqz	a3,800019b2 <copyinstr+0xa8>
{
    8000190c:	715d                	addi	sp,sp,-80
    8000190e:	e486                	sd	ra,72(sp)
    80001910:	e0a2                	sd	s0,64(sp)
    80001912:	fc26                	sd	s1,56(sp)
    80001914:	f84a                	sd	s2,48(sp)
    80001916:	f44e                	sd	s3,40(sp)
    80001918:	f052                	sd	s4,32(sp)
    8000191a:	ec56                	sd	s5,24(sp)
    8000191c:	e85a                	sd	s6,16(sp)
    8000191e:	e45e                	sd	s7,8(sp)
    80001920:	0880                	addi	s0,sp,80
    80001922:	8a2a                	mv	s4,a0
    80001924:	8b2e                	mv	s6,a1
    80001926:	8bb2                	mv	s7,a2
    80001928:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000192a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000192c:	6985                	lui	s3,0x1
    8000192e:	a035                	j	8000195a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001930:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001934:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001936:	0017b793          	seqz	a5,a5
    8000193a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000193e:	60a6                	ld	ra,72(sp)
    80001940:	6406                	ld	s0,64(sp)
    80001942:	74e2                	ld	s1,56(sp)
    80001944:	7942                	ld	s2,48(sp)
    80001946:	79a2                	ld	s3,40(sp)
    80001948:	7a02                	ld	s4,32(sp)
    8000194a:	6ae2                	ld	s5,24(sp)
    8000194c:	6b42                	ld	s6,16(sp)
    8000194e:	6ba2                	ld	s7,8(sp)
    80001950:	6161                	addi	sp,sp,80
    80001952:	8082                	ret
    srcva = va0 + PGSIZE;
    80001954:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001958:	c8a9                	beqz	s1,800019aa <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000195a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000195e:	85ca                	mv	a1,s2
    80001960:	8552                	mv	a0,s4
    80001962:	00000097          	auipc	ra,0x0
    80001966:	882080e7          	jalr	-1918(ra) # 800011e4 <walkaddr>
    if(pa0 == 0)
    8000196a:	c131                	beqz	a0,800019ae <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000196c:	41790833          	sub	a6,s2,s7
    80001970:	984e                	add	a6,a6,s3
    if(n > max)
    80001972:	0104f363          	bgeu	s1,a6,80001978 <copyinstr+0x6e>
    80001976:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001978:	955e                	add	a0,a0,s7
    8000197a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000197e:	fc080be3          	beqz	a6,80001954 <copyinstr+0x4a>
    80001982:	985a                	add	a6,a6,s6
    80001984:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001986:	41650633          	sub	a2,a0,s6
    8000198a:	14fd                	addi	s1,s1,-1
    8000198c:	9b26                	add	s6,s6,s1
    8000198e:	00f60733          	add	a4,a2,a5
    80001992:	00074703          	lbu	a4,0(a4)
    80001996:	df49                	beqz	a4,80001930 <copyinstr+0x26>
        *dst = *p;
    80001998:	00e78023          	sb	a4,0(a5)
      --max;
    8000199c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019a0:	0785                	addi	a5,a5,1
    while(n > 0){
    800019a2:	ff0796e3          	bne	a5,a6,8000198e <copyinstr+0x84>
      dst++;
    800019a6:	8b42                	mv	s6,a6
    800019a8:	b775                	j	80001954 <copyinstr+0x4a>
    800019aa:	4781                	li	a5,0
    800019ac:	b769                	j	80001936 <copyinstr+0x2c>
      return -1;
    800019ae:	557d                	li	a0,-1
    800019b0:	b779                	j	8000193e <copyinstr+0x34>
  int got_null = 0;
    800019b2:	4781                	li	a5,0
  if(got_null){
    800019b4:	0017b793          	seqz	a5,a5
    800019b8:	40f00533          	neg	a0,a5
}
    800019bc:	8082                	ret

00000000800019be <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800019be:	7139                	addi	sp,sp,-64
    800019c0:	fc06                	sd	ra,56(sp)
    800019c2:	f822                	sd	s0,48(sp)
    800019c4:	f426                	sd	s1,40(sp)
    800019c6:	f04a                	sd	s2,32(sp)
    800019c8:	ec4e                	sd	s3,24(sp)
    800019ca:	e852                	sd	s4,16(sp)
    800019cc:	e456                	sd	s5,8(sp)
    800019ce:	e05a                	sd	s6,0(sp)
    800019d0:	0080                	addi	s0,sp,64
    800019d2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d4:	00010497          	auipc	s1,0x10
    800019d8:	e1c48493          	addi	s1,s1,-484 # 800117f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019dc:	8b26                	mv	s6,s1
    800019de:	00006a97          	auipc	s5,0x6
    800019e2:	622a8a93          	addi	s5,s5,1570 # 80008000 <etext>
    800019e6:	04000937          	lui	s2,0x4000
    800019ea:	197d                	addi	s2,s2,-1
    800019ec:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ee:	00016a17          	auipc	s4,0x16
    800019f2:	802a0a13          	addi	s4,s4,-2046 # 800171f0 <tickslock>
    char *pa = kalloc();
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	278080e7          	jalr	632(ra) # 80000c6e <kalloc>
    800019fe:	862a                	mv	a2,a0
    if(pa == 0)
    80001a00:	c131                	beqz	a0,80001a44 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a02:	416485b3          	sub	a1,s1,s6
    80001a06:	858d                	srai	a1,a1,0x3
    80001a08:	000ab783          	ld	a5,0(s5)
    80001a0c:	02f585b3          	mul	a1,a1,a5
    80001a10:	2585                	addiw	a1,a1,1
    80001a12:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a16:	4719                	li	a4,6
    80001a18:	6685                	lui	a3,0x1
    80001a1a:	40b905b3          	sub	a1,s2,a1
    80001a1e:	854e                	mv	a0,s3
    80001a20:	00000097          	auipc	ra,0x0
    80001a24:	8a6080e7          	jalr	-1882(ra) # 800012c6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a28:	16848493          	addi	s1,s1,360
    80001a2c:	fd4495e3          	bne	s1,s4,800019f6 <proc_mapstacks+0x38>
  }
}
    80001a30:	70e2                	ld	ra,56(sp)
    80001a32:	7442                	ld	s0,48(sp)
    80001a34:	74a2                	ld	s1,40(sp)
    80001a36:	7902                	ld	s2,32(sp)
    80001a38:	69e2                	ld	s3,24(sp)
    80001a3a:	6a42                	ld	s4,16(sp)
    80001a3c:	6aa2                	ld	s5,8(sp)
    80001a3e:	6b02                	ld	s6,0(sp)
    80001a40:	6121                	addi	sp,sp,64
    80001a42:	8082                	ret
      panic("kalloc");
    80001a44:	00006517          	auipc	a0,0x6
    80001a48:	7c450513          	addi	a0,a0,1988 # 80008208 <digits+0x198>
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	c7a080e7          	jalr	-902(ra) # 800006c6 <panic>

0000000080001a54 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a54:	7139                	addi	sp,sp,-64
    80001a56:	fc06                	sd	ra,56(sp)
    80001a58:	f822                	sd	s0,48(sp)
    80001a5a:	f426                	sd	s1,40(sp)
    80001a5c:	f04a                	sd	s2,32(sp)
    80001a5e:	ec4e                	sd	s3,24(sp)
    80001a60:	e852                	sd	s4,16(sp)
    80001a62:	e456                	sd	s5,8(sp)
    80001a64:	e05a                	sd	s6,0(sp)
    80001a66:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a68:	00006597          	auipc	a1,0x6
    80001a6c:	7a858593          	addi	a1,a1,1960 # 80008210 <digits+0x1a0>
    80001a70:	00010517          	auipc	a0,0x10
    80001a74:	95050513          	addi	a0,a0,-1712 # 800113c0 <pid_lock>
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	256080e7          	jalr	598(ra) # 80000cce <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a80:	00006597          	auipc	a1,0x6
    80001a84:	79858593          	addi	a1,a1,1944 # 80008218 <digits+0x1a8>
    80001a88:	00010517          	auipc	a0,0x10
    80001a8c:	95050513          	addi	a0,a0,-1712 # 800113d8 <wait_lock>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	23e080e7          	jalr	574(ra) # 80000cce <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a98:	00010497          	auipc	s1,0x10
    80001a9c:	d5848493          	addi	s1,s1,-680 # 800117f0 <proc>
      initlock(&p->lock, "proc");
    80001aa0:	00006b17          	auipc	s6,0x6
    80001aa4:	788b0b13          	addi	s6,s6,1928 # 80008228 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001aa8:	8aa6                	mv	s5,s1
    80001aaa:	00006a17          	auipc	s4,0x6
    80001aae:	556a0a13          	addi	s4,s4,1366 # 80008000 <etext>
    80001ab2:	04000937          	lui	s2,0x4000
    80001ab6:	197d                	addi	s2,s2,-1
    80001ab8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aba:	00015997          	auipc	s3,0x15
    80001abe:	73698993          	addi	s3,s3,1846 # 800171f0 <tickslock>
      initlock(&p->lock, "proc");
    80001ac2:	85da                	mv	a1,s6
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	208080e7          	jalr	520(ra) # 80000cce <initlock>
      p->state = UNUSED;
    80001ace:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001ad2:	415487b3          	sub	a5,s1,s5
    80001ad6:	878d                	srai	a5,a5,0x3
    80001ad8:	000a3703          	ld	a4,0(s4)
    80001adc:	02e787b3          	mul	a5,a5,a4
    80001ae0:	2785                	addiw	a5,a5,1
    80001ae2:	00d7979b          	slliw	a5,a5,0xd
    80001ae6:	40f907b3          	sub	a5,s2,a5
    80001aea:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aec:	16848493          	addi	s1,s1,360
    80001af0:	fd3499e3          	bne	s1,s3,80001ac2 <procinit+0x6e>
  }
}
    80001af4:	70e2                	ld	ra,56(sp)
    80001af6:	7442                	ld	s0,48(sp)
    80001af8:	74a2                	ld	s1,40(sp)
    80001afa:	7902                	ld	s2,32(sp)
    80001afc:	69e2                	ld	s3,24(sp)
    80001afe:	6a42                	ld	s4,16(sp)
    80001b00:	6aa2                	ld	s5,8(sp)
    80001b02:	6b02                	ld	s6,0(sp)
    80001b04:	6121                	addi	sp,sp,64
    80001b06:	8082                	ret

0000000080001b08 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b08:	1141                	addi	sp,sp,-16
    80001b0a:	e422                	sd	s0,8(sp)
    80001b0c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b0e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b10:	2501                	sext.w	a0,a0
    80001b12:	6422                	ld	s0,8(sp)
    80001b14:	0141                	addi	sp,sp,16
    80001b16:	8082                	ret

0000000080001b18 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001b18:	1141                	addi	sp,sp,-16
    80001b1a:	e422                	sd	s0,8(sp)
    80001b1c:	0800                	addi	s0,sp,16
    80001b1e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b20:	2781                	sext.w	a5,a5
    80001b22:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b24:	00010517          	auipc	a0,0x10
    80001b28:	8cc50513          	addi	a0,a0,-1844 # 800113f0 <cpus>
    80001b2c:	953e                	add	a0,a0,a5
    80001b2e:	6422                	ld	s0,8(sp)
    80001b30:	0141                	addi	sp,sp,16
    80001b32:	8082                	ret

0000000080001b34 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001b34:	1101                	addi	sp,sp,-32
    80001b36:	ec06                	sd	ra,24(sp)
    80001b38:	e822                	sd	s0,16(sp)
    80001b3a:	e426                	sd	s1,8(sp)
    80001b3c:	1000                	addi	s0,sp,32
  push_off();
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	1d4080e7          	jalr	468(ra) # 80000d12 <push_off>
    80001b46:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b48:	2781                	sext.w	a5,a5
    80001b4a:	079e                	slli	a5,a5,0x7
    80001b4c:	00010717          	auipc	a4,0x10
    80001b50:	87470713          	addi	a4,a4,-1932 # 800113c0 <pid_lock>
    80001b54:	97ba                	add	a5,a5,a4
    80001b56:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	25a080e7          	jalr	602(ra) # 80000db2 <pop_off>
  return p;
}
    80001b60:	8526                	mv	a0,s1
    80001b62:	60e2                	ld	ra,24(sp)
    80001b64:	6442                	ld	s0,16(sp)
    80001b66:	64a2                	ld	s1,8(sp)
    80001b68:	6105                	addi	sp,sp,32
    80001b6a:	8082                	ret

0000000080001b6c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b6c:	1141                	addi	sp,sp,-16
    80001b6e:	e406                	sd	ra,8(sp)
    80001b70:	e022                	sd	s0,0(sp)
    80001b72:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b74:	00000097          	auipc	ra,0x0
    80001b78:	fc0080e7          	jalr	-64(ra) # 80001b34 <myproc>
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	296080e7          	jalr	662(ra) # 80000e12 <release>

  if (first) {
    80001b84:	00007797          	auipc	a5,0x7
    80001b88:	cfc7a783          	lw	a5,-772(a5) # 80008880 <first.1>
    80001b8c:	eb89                	bnez	a5,80001b9e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b8e:	00001097          	auipc	ra,0x1
    80001b92:	d30080e7          	jalr	-720(ra) # 800028be <usertrapret>
}
    80001b96:	60a2                	ld	ra,8(sp)
    80001b98:	6402                	ld	s0,0(sp)
    80001b9a:	0141                	addi	sp,sp,16
    80001b9c:	8082                	ret
    first = 0;
    80001b9e:	00007797          	auipc	a5,0x7
    80001ba2:	ce07a123          	sw	zero,-798(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001ba6:	4505                	li	a0,1
    80001ba8:	00002097          	auipc	ra,0x2
    80001bac:	ac6080e7          	jalr	-1338(ra) # 8000366e <fsinit>
    80001bb0:	bff9                	j	80001b8e <forkret+0x22>

0000000080001bb2 <allocpid>:
{
    80001bb2:	1101                	addi	sp,sp,-32
    80001bb4:	ec06                	sd	ra,24(sp)
    80001bb6:	e822                	sd	s0,16(sp)
    80001bb8:	e426                	sd	s1,8(sp)
    80001bba:	e04a                	sd	s2,0(sp)
    80001bbc:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bbe:	00010917          	auipc	s2,0x10
    80001bc2:	80290913          	addi	s2,s2,-2046 # 800113c0 <pid_lock>
    80001bc6:	854a                	mv	a0,s2
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	196080e7          	jalr	406(ra) # 80000d5e <acquire>
  pid = nextpid;
    80001bd0:	00007797          	auipc	a5,0x7
    80001bd4:	cb478793          	addi	a5,a5,-844 # 80008884 <nextpid>
    80001bd8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bda:	0014871b          	addiw	a4,s1,1
    80001bde:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001be0:	854a                	mv	a0,s2
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	230080e7          	jalr	560(ra) # 80000e12 <release>
}
    80001bea:	8526                	mv	a0,s1
    80001bec:	60e2                	ld	ra,24(sp)
    80001bee:	6442                	ld	s0,16(sp)
    80001bf0:	64a2                	ld	s1,8(sp)
    80001bf2:	6902                	ld	s2,0(sp)
    80001bf4:	6105                	addi	sp,sp,32
    80001bf6:	8082                	ret

0000000080001bf8 <proc_pagetable>:
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	e04a                	sd	s2,0(sp)
    80001c02:	1000                	addi	s0,sp,32
    80001c04:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	8aa080e7          	jalr	-1878(ra) # 800014b0 <uvmcreate>
    80001c0e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c10:	c121                	beqz	a0,80001c50 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c12:	4729                	li	a4,10
    80001c14:	00005697          	auipc	a3,0x5
    80001c18:	3ec68693          	addi	a3,a3,1004 # 80007000 <_trampoline>
    80001c1c:	6605                	lui	a2,0x1
    80001c1e:	040005b7          	lui	a1,0x4000
    80001c22:	15fd                	addi	a1,a1,-1
    80001c24:	05b2                	slli	a1,a1,0xc
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	600080e7          	jalr	1536(ra) # 80001226 <mappages>
    80001c2e:	02054863          	bltz	a0,80001c5e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c32:	4719                	li	a4,6
    80001c34:	05893683          	ld	a3,88(s2)
    80001c38:	6605                	lui	a2,0x1
    80001c3a:	020005b7          	lui	a1,0x2000
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05b6                	slli	a1,a1,0xd
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	5e2080e7          	jalr	1506(ra) # 80001226 <mappages>
    80001c4c:	02054163          	bltz	a0,80001c6e <proc_pagetable+0x76>
}
    80001c50:	8526                	mv	a0,s1
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret
    uvmfree(pagetable, 0);
    80001c5e:	4581                	li	a1,0
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	a52080e7          	jalr	-1454(ra) # 800016b4 <uvmfree>
    return 0;
    80001c6a:	4481                	li	s1,0
    80001c6c:	b7d5                	j	80001c50 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c6e:	4681                	li	a3,0
    80001c70:	4605                	li	a2,1
    80001c72:	040005b7          	lui	a1,0x4000
    80001c76:	15fd                	addi	a1,a1,-1
    80001c78:	05b2                	slli	a1,a1,0xc
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	770080e7          	jalr	1904(ra) # 800013ec <uvmunmap>
    uvmfree(pagetable, 0);
    80001c84:	4581                	li	a1,0
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	a2c080e7          	jalr	-1492(ra) # 800016b4 <uvmfree>
    return 0;
    80001c90:	4481                	li	s1,0
    80001c92:	bf7d                	j	80001c50 <proc_pagetable+0x58>

0000000080001c94 <proc_freepagetable>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	e04a                	sd	s2,0(sp)
    80001c9e:	1000                	addi	s0,sp,32
    80001ca0:	84aa                	mv	s1,a0
    80001ca2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca4:	4681                	li	a3,0
    80001ca6:	4605                	li	a2,1
    80001ca8:	040005b7          	lui	a1,0x4000
    80001cac:	15fd                	addi	a1,a1,-1
    80001cae:	05b2                	slli	a1,a1,0xc
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	73c080e7          	jalr	1852(ra) # 800013ec <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cb8:	4681                	li	a3,0
    80001cba:	4605                	li	a2,1
    80001cbc:	020005b7          	lui	a1,0x2000
    80001cc0:	15fd                	addi	a1,a1,-1
    80001cc2:	05b6                	slli	a1,a1,0xd
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	726080e7          	jalr	1830(ra) # 800013ec <uvmunmap>
  uvmfree(pagetable, sz);
    80001cce:	85ca                	mv	a1,s2
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	9e2080e7          	jalr	-1566(ra) # 800016b4 <uvmfree>
}
    80001cda:	60e2                	ld	ra,24(sp)
    80001cdc:	6442                	ld	s0,16(sp)
    80001cde:	64a2                	ld	s1,8(sp)
    80001ce0:	6902                	ld	s2,0(sp)
    80001ce2:	6105                	addi	sp,sp,32
    80001ce4:	8082                	ret

0000000080001ce6 <freeproc>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	1000                	addi	s0,sp,32
    80001cf0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cf2:	6d28                	ld	a0,88(a0)
    80001cf4:	c509                	beqz	a0,80001cfe <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	e7c080e7          	jalr	-388(ra) # 80000b72 <kfree>
  p->trapframe = 0;
    80001cfe:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d02:	68a8                	ld	a0,80(s1)
    80001d04:	c511                	beqz	a0,80001d10 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d06:	64ac                	ld	a1,72(s1)
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	f8c080e7          	jalr	-116(ra) # 80001c94 <proc_freepagetable>
  p->pagetable = 0;
    80001d10:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d14:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d18:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d1c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d20:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d24:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d28:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d2c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d30:	0004ac23          	sw	zero,24(s1)
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <allocproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	e04a                	sd	s2,0(sp)
    80001d48:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d4a:	00010497          	auipc	s1,0x10
    80001d4e:	aa648493          	addi	s1,s1,-1370 # 800117f0 <proc>
    80001d52:	00015917          	auipc	s2,0x15
    80001d56:	49e90913          	addi	s2,s2,1182 # 800171f0 <tickslock>
    acquire(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	002080e7          	jalr	2(ra) # 80000d5e <acquire>
    if(p->state == UNUSED) {
    80001d64:	4c9c                	lw	a5,24(s1)
    80001d66:	cf81                	beqz	a5,80001d7e <allocproc+0x40>
      release(&p->lock);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	0a8080e7          	jalr	168(ra) # 80000e12 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d72:	16848493          	addi	s1,s1,360
    80001d76:	ff2492e3          	bne	s1,s2,80001d5a <allocproc+0x1c>
  return 0;
    80001d7a:	4481                	li	s1,0
    80001d7c:	a889                	j	80001dce <allocproc+0x90>
  p->pid = allocpid();
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e34080e7          	jalr	-460(ra) # 80001bb2 <allocpid>
    80001d86:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d88:	4785                	li	a5,1
    80001d8a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	ee2080e7          	jalr	-286(ra) # 80000c6e <kalloc>
    80001d94:	892a                	mv	s2,a0
    80001d96:	eca8                	sd	a0,88(s1)
    80001d98:	c131                	beqz	a0,80001ddc <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	e5c080e7          	jalr	-420(ra) # 80001bf8 <proc_pagetable>
    80001da4:	892a                	mv	s2,a0
    80001da6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001da8:	c531                	beqz	a0,80001df4 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001daa:	07000613          	li	a2,112
    80001dae:	4581                	li	a1,0
    80001db0:	06048513          	addi	a0,s1,96
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	0a6080e7          	jalr	166(ra) # 80000e5a <memset>
  p->context.ra = (uint64)forkret;
    80001dbc:	00000797          	auipc	a5,0x0
    80001dc0:	db078793          	addi	a5,a5,-592 # 80001b6c <forkret>
    80001dc4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dc6:	60bc                	ld	a5,64(s1)
    80001dc8:	6705                	lui	a4,0x1
    80001dca:	97ba                	add	a5,a5,a4
    80001dcc:	f4bc                	sd	a5,104(s1)
}
    80001dce:	8526                	mv	a0,s1
    80001dd0:	60e2                	ld	ra,24(sp)
    80001dd2:	6442                	ld	s0,16(sp)
    80001dd4:	64a2                	ld	s1,8(sp)
    80001dd6:	6902                	ld	s2,0(sp)
    80001dd8:	6105                	addi	sp,sp,32
    80001dda:	8082                	ret
    freeproc(p);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	f08080e7          	jalr	-248(ra) # 80001ce6 <freeproc>
    release(&p->lock);
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	02a080e7          	jalr	42(ra) # 80000e12 <release>
    return 0;
    80001df0:	84ca                	mv	s1,s2
    80001df2:	bff1                	j	80001dce <allocproc+0x90>
    freeproc(p);
    80001df4:	8526                	mv	a0,s1
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	ef0080e7          	jalr	-272(ra) # 80001ce6 <freeproc>
    release(&p->lock);
    80001dfe:	8526                	mv	a0,s1
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	012080e7          	jalr	18(ra) # 80000e12 <release>
    return 0;
    80001e08:	84ca                	mv	s1,s2
    80001e0a:	b7d1                	j	80001dce <allocproc+0x90>

0000000080001e0c <userinit>:
{
    80001e0c:	1101                	addi	sp,sp,-32
    80001e0e:	ec06                	sd	ra,24(sp)
    80001e10:	e822                	sd	s0,16(sp)
    80001e12:	e426                	sd	s1,8(sp)
    80001e14:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	f28080e7          	jalr	-216(ra) # 80001d3e <allocproc>
    80001e1e:	84aa                	mv	s1,a0
  initproc = p;
    80001e20:	00007797          	auipc	a5,0x7
    80001e24:	aca7bc23          	sd	a0,-1320(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e28:	03400613          	li	a2,52
    80001e2c:	00007597          	auipc	a1,0x7
    80001e30:	a6458593          	addi	a1,a1,-1436 # 80008890 <initcode>
    80001e34:	6928                	ld	a0,80(a0)
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	6a8080e7          	jalr	1704(ra) # 800014de <uvmfirst>
  p->sz = PGSIZE;
    80001e3e:	6785                	lui	a5,0x1
    80001e40:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e42:	6cb8                	ld	a4,88(s1)
    80001e44:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e48:	6cb8                	ld	a4,88(s1)
    80001e4a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e4c:	4641                	li	a2,16
    80001e4e:	00006597          	auipc	a1,0x6
    80001e52:	3e258593          	addi	a1,a1,994 # 80008230 <digits+0x1c0>
    80001e56:	15848513          	addi	a0,s1,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	14a080e7          	jalr	330(ra) # 80000fa4 <safestrcpy>
  p->cwd = namei("/");
    80001e62:	00006517          	auipc	a0,0x6
    80001e66:	3de50513          	addi	a0,a0,990 # 80008240 <digits+0x1d0>
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	226080e7          	jalr	550(ra) # 80004090 <namei>
    80001e72:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e76:	478d                	li	a5,3
    80001e78:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	f96080e7          	jalr	-106(ra) # 80000e12 <release>
}
    80001e84:	60e2                	ld	ra,24(sp)
    80001e86:	6442                	ld	s0,16(sp)
    80001e88:	64a2                	ld	s1,8(sp)
    80001e8a:	6105                	addi	sp,sp,32
    80001e8c:	8082                	ret

0000000080001e8e <growproc>:
{
    80001e8e:	1101                	addi	sp,sp,-32
    80001e90:	ec06                	sd	ra,24(sp)
    80001e92:	e822                	sd	s0,16(sp)
    80001e94:	e426                	sd	s1,8(sp)
    80001e96:	e04a                	sd	s2,0(sp)
    80001e98:	1000                	addi	s0,sp,32
    80001e9a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	c98080e7          	jalr	-872(ra) # 80001b34 <myproc>
    80001ea4:	84aa                	mv	s1,a0
  sz = p->sz;
    80001ea6:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001ea8:	01204c63          	bgtz	s2,80001ec0 <growproc+0x32>
  } else if(n < 0){
    80001eac:	02094663          	bltz	s2,80001ed8 <growproc+0x4a>
  p->sz = sz;
    80001eb0:	e4ac                	sd	a1,72(s1)
  return 0;
    80001eb2:	4501                	li	a0,0
}
    80001eb4:	60e2                	ld	ra,24(sp)
    80001eb6:	6442                	ld	s0,16(sp)
    80001eb8:	64a2                	ld	s1,8(sp)
    80001eba:	6902                	ld	s2,0(sp)
    80001ebc:	6105                	addi	sp,sp,32
    80001ebe:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001ec0:	4691                	li	a3,4
    80001ec2:	00b90633          	add	a2,s2,a1
    80001ec6:	6928                	ld	a0,80(a0)
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	6d0080e7          	jalr	1744(ra) # 80001598 <uvmalloc>
    80001ed0:	85aa                	mv	a1,a0
    80001ed2:	fd79                	bnez	a0,80001eb0 <growproc+0x22>
      return -1;
    80001ed4:	557d                	li	a0,-1
    80001ed6:	bff9                	j	80001eb4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ed8:	00b90633          	add	a2,s2,a1
    80001edc:	6928                	ld	a0,80(a0)
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	672080e7          	jalr	1650(ra) # 80001550 <uvmdealloc>
    80001ee6:	85aa                	mv	a1,a0
    80001ee8:	b7e1                	j	80001eb0 <growproc+0x22>

0000000080001eea <fork>:
{
    80001eea:	7139                	addi	sp,sp,-64
    80001eec:	fc06                	sd	ra,56(sp)
    80001eee:	f822                	sd	s0,48(sp)
    80001ef0:	f426                	sd	s1,40(sp)
    80001ef2:	f04a                	sd	s2,32(sp)
    80001ef4:	ec4e                	sd	s3,24(sp)
    80001ef6:	e852                	sd	s4,16(sp)
    80001ef8:	e456                	sd	s5,8(sp)
    80001efa:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	c38080e7          	jalr	-968(ra) # 80001b34 <myproc>
    80001f04:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	e38080e7          	jalr	-456(ra) # 80001d3e <allocproc>
    80001f0e:	10050c63          	beqz	a0,80002026 <fork+0x13c>
    80001f12:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f14:	048ab603          	ld	a2,72(s5)
    80001f18:	692c                	ld	a1,80(a0)
    80001f1a:	050ab503          	ld	a0,80(s5)
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	7ce080e7          	jalr	1998(ra) # 800016ec <uvmcopy>
    80001f26:	04054863          	bltz	a0,80001f76 <fork+0x8c>
  np->sz = p->sz;
    80001f2a:	048ab783          	ld	a5,72(s5)
    80001f2e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f32:	058ab683          	ld	a3,88(s5)
    80001f36:	87b6                	mv	a5,a3
    80001f38:	058a3703          	ld	a4,88(s4)
    80001f3c:	12068693          	addi	a3,a3,288
    80001f40:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f44:	6788                	ld	a0,8(a5)
    80001f46:	6b8c                	ld	a1,16(a5)
    80001f48:	6f90                	ld	a2,24(a5)
    80001f4a:	01073023          	sd	a6,0(a4)
    80001f4e:	e708                	sd	a0,8(a4)
    80001f50:	eb0c                	sd	a1,16(a4)
    80001f52:	ef10                	sd	a2,24(a4)
    80001f54:	02078793          	addi	a5,a5,32
    80001f58:	02070713          	addi	a4,a4,32
    80001f5c:	fed792e3          	bne	a5,a3,80001f40 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f60:	058a3783          	ld	a5,88(s4)
    80001f64:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f68:	0d0a8493          	addi	s1,s5,208
    80001f6c:	0d0a0913          	addi	s2,s4,208
    80001f70:	150a8993          	addi	s3,s5,336
    80001f74:	a00d                	j	80001f96 <fork+0xac>
    freeproc(np);
    80001f76:	8552                	mv	a0,s4
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	d6e080e7          	jalr	-658(ra) # 80001ce6 <freeproc>
    release(&np->lock);
    80001f80:	8552                	mv	a0,s4
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	e90080e7          	jalr	-368(ra) # 80000e12 <release>
    return -1;
    80001f8a:	597d                	li	s2,-1
    80001f8c:	a059                	j	80002012 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001f8e:	04a1                	addi	s1,s1,8
    80001f90:	0921                	addi	s2,s2,8
    80001f92:	01348b63          	beq	s1,s3,80001fa8 <fork+0xbe>
    if(p->ofile[i])
    80001f96:	6088                	ld	a0,0(s1)
    80001f98:	d97d                	beqz	a0,80001f8e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f9a:	00002097          	auipc	ra,0x2
    80001f9e:	78c080e7          	jalr	1932(ra) # 80004726 <filedup>
    80001fa2:	00a93023          	sd	a0,0(s2)
    80001fa6:	b7e5                	j	80001f8e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001fa8:	150ab503          	ld	a0,336(s5)
    80001fac:	00002097          	auipc	ra,0x2
    80001fb0:	900080e7          	jalr	-1792(ra) # 800038ac <idup>
    80001fb4:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fb8:	4641                	li	a2,16
    80001fba:	158a8593          	addi	a1,s5,344
    80001fbe:	158a0513          	addi	a0,s4,344
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	fe2080e7          	jalr	-30(ra) # 80000fa4 <safestrcpy>
  pid = np->pid;
    80001fca:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001fce:	8552                	mv	a0,s4
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	e42080e7          	jalr	-446(ra) # 80000e12 <release>
  acquire(&wait_lock);
    80001fd8:	0000f497          	auipc	s1,0xf
    80001fdc:	40048493          	addi	s1,s1,1024 # 800113d8 <wait_lock>
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	d7c080e7          	jalr	-644(ra) # 80000d5e <acquire>
  np->parent = p;
    80001fea:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	e22080e7          	jalr	-478(ra) # 80000e12 <release>
  acquire(&np->lock);
    80001ff8:	8552                	mv	a0,s4
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	d64080e7          	jalr	-668(ra) # 80000d5e <acquire>
  np->state = RUNNABLE;
    80002002:	478d                	li	a5,3
    80002004:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002008:	8552                	mv	a0,s4
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	e08080e7          	jalr	-504(ra) # 80000e12 <release>
}
    80002012:	854a                	mv	a0,s2
    80002014:	70e2                	ld	ra,56(sp)
    80002016:	7442                	ld	s0,48(sp)
    80002018:	74a2                	ld	s1,40(sp)
    8000201a:	7902                	ld	s2,32(sp)
    8000201c:	69e2                	ld	s3,24(sp)
    8000201e:	6a42                	ld	s4,16(sp)
    80002020:	6aa2                	ld	s5,8(sp)
    80002022:	6121                	addi	sp,sp,64
    80002024:	8082                	ret
    return -1;
    80002026:	597d                	li	s2,-1
    80002028:	b7ed                	j	80002012 <fork+0x128>

000000008000202a <scheduler>:
{
    8000202a:	7139                	addi	sp,sp,-64
    8000202c:	fc06                	sd	ra,56(sp)
    8000202e:	f822                	sd	s0,48(sp)
    80002030:	f426                	sd	s1,40(sp)
    80002032:	f04a                	sd	s2,32(sp)
    80002034:	ec4e                	sd	s3,24(sp)
    80002036:	e852                	sd	s4,16(sp)
    80002038:	e456                	sd	s5,8(sp)
    8000203a:	e05a                	sd	s6,0(sp)
    8000203c:	0080                	addi	s0,sp,64
    8000203e:	8792                	mv	a5,tp
  int id = r_tp();
    80002040:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002042:	00779a93          	slli	s5,a5,0x7
    80002046:	0000f717          	auipc	a4,0xf
    8000204a:	37a70713          	addi	a4,a4,890 # 800113c0 <pid_lock>
    8000204e:	9756                	add	a4,a4,s5
    80002050:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002054:	0000f717          	auipc	a4,0xf
    80002058:	3a470713          	addi	a4,a4,932 # 800113f8 <cpus+0x8>
    8000205c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000205e:	498d                	li	s3,3
        p->state = RUNNING;
    80002060:	4b11                	li	s6,4
        c->proc = p;
    80002062:	079e                	slli	a5,a5,0x7
    80002064:	0000fa17          	auipc	s4,0xf
    80002068:	35ca0a13          	addi	s4,s4,860 # 800113c0 <pid_lock>
    8000206c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000206e:	00015917          	auipc	s2,0x15
    80002072:	18290913          	addi	s2,s2,386 # 800171f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002076:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000207a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000207e:	10079073          	csrw	sstatus,a5
    80002082:	0000f497          	auipc	s1,0xf
    80002086:	76e48493          	addi	s1,s1,1902 # 800117f0 <proc>
    8000208a:	a811                	j	8000209e <scheduler+0x74>
      release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	d84080e7          	jalr	-636(ra) # 80000e12 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002096:	16848493          	addi	s1,s1,360
    8000209a:	fd248ee3          	beq	s1,s2,80002076 <scheduler+0x4c>
      acquire(&p->lock);
    8000209e:	8526                	mv	a0,s1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	cbe080e7          	jalr	-834(ra) # 80000d5e <acquire>
      if(p->state == RUNNABLE) {
    800020a8:	4c9c                	lw	a5,24(s1)
    800020aa:	ff3791e3          	bne	a5,s3,8000208c <scheduler+0x62>
        p->state = RUNNING;
    800020ae:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020b2:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020b6:	06048593          	addi	a1,s1,96
    800020ba:	8556                	mv	a0,s5
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	758080e7          	jalr	1880(ra) # 80002814 <swtch>
        c->proc = 0;
    800020c4:	020a3823          	sd	zero,48(s4)
    800020c8:	b7d1                	j	8000208c <scheduler+0x62>

00000000800020ca <sched>:
{
    800020ca:	7179                	addi	sp,sp,-48
    800020cc:	f406                	sd	ra,40(sp)
    800020ce:	f022                	sd	s0,32(sp)
    800020d0:	ec26                	sd	s1,24(sp)
    800020d2:	e84a                	sd	s2,16(sp)
    800020d4:	e44e                	sd	s3,8(sp)
    800020d6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	a5c080e7          	jalr	-1444(ra) # 80001b34 <myproc>
    800020e0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	c02080e7          	jalr	-1022(ra) # 80000ce4 <holding>
    800020ea:	c93d                	beqz	a0,80002160 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ec:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020ee:	2781                	sext.w	a5,a5
    800020f0:	079e                	slli	a5,a5,0x7
    800020f2:	0000f717          	auipc	a4,0xf
    800020f6:	2ce70713          	addi	a4,a4,718 # 800113c0 <pid_lock>
    800020fa:	97ba                	add	a5,a5,a4
    800020fc:	0a87a703          	lw	a4,168(a5)
    80002100:	4785                	li	a5,1
    80002102:	06f71763          	bne	a4,a5,80002170 <sched+0xa6>
  if(p->state == RUNNING)
    80002106:	4c98                	lw	a4,24(s1)
    80002108:	4791                	li	a5,4
    8000210a:	06f70b63          	beq	a4,a5,80002180 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000210e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002112:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002114:	efb5                	bnez	a5,80002190 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002116:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002118:	0000f917          	auipc	s2,0xf
    8000211c:	2a890913          	addi	s2,s2,680 # 800113c0 <pid_lock>
    80002120:	2781                	sext.w	a5,a5
    80002122:	079e                	slli	a5,a5,0x7
    80002124:	97ca                	add	a5,a5,s2
    80002126:	0ac7a983          	lw	s3,172(a5)
    8000212a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000212c:	2781                	sext.w	a5,a5
    8000212e:	079e                	slli	a5,a5,0x7
    80002130:	0000f597          	auipc	a1,0xf
    80002134:	2c858593          	addi	a1,a1,712 # 800113f8 <cpus+0x8>
    80002138:	95be                	add	a1,a1,a5
    8000213a:	06048513          	addi	a0,s1,96
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	6d6080e7          	jalr	1750(ra) # 80002814 <swtch>
    80002146:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002148:	2781                	sext.w	a5,a5
    8000214a:	079e                	slli	a5,a5,0x7
    8000214c:	97ca                	add	a5,a5,s2
    8000214e:	0b37a623          	sw	s3,172(a5)
}
    80002152:	70a2                	ld	ra,40(sp)
    80002154:	7402                	ld	s0,32(sp)
    80002156:	64e2                	ld	s1,24(sp)
    80002158:	6942                	ld	s2,16(sp)
    8000215a:	69a2                	ld	s3,8(sp)
    8000215c:	6145                	addi	sp,sp,48
    8000215e:	8082                	ret
    panic("sched p->lock");
    80002160:	00006517          	auipc	a0,0x6
    80002164:	0e850513          	addi	a0,a0,232 # 80008248 <digits+0x1d8>
    80002168:	ffffe097          	auipc	ra,0xffffe
    8000216c:	55e080e7          	jalr	1374(ra) # 800006c6 <panic>
    panic("sched locks");
    80002170:	00006517          	auipc	a0,0x6
    80002174:	0e850513          	addi	a0,a0,232 # 80008258 <digits+0x1e8>
    80002178:	ffffe097          	auipc	ra,0xffffe
    8000217c:	54e080e7          	jalr	1358(ra) # 800006c6 <panic>
    panic("sched running");
    80002180:	00006517          	auipc	a0,0x6
    80002184:	0e850513          	addi	a0,a0,232 # 80008268 <digits+0x1f8>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	53e080e7          	jalr	1342(ra) # 800006c6 <panic>
    panic("sched interruptible");
    80002190:	00006517          	auipc	a0,0x6
    80002194:	0e850513          	addi	a0,a0,232 # 80008278 <digits+0x208>
    80002198:	ffffe097          	auipc	ra,0xffffe
    8000219c:	52e080e7          	jalr	1326(ra) # 800006c6 <panic>

00000000800021a0 <yield>:
{
    800021a0:	1101                	addi	sp,sp,-32
    800021a2:	ec06                	sd	ra,24(sp)
    800021a4:	e822                	sd	s0,16(sp)
    800021a6:	e426                	sd	s1,8(sp)
    800021a8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	98a080e7          	jalr	-1654(ra) # 80001b34 <myproc>
    800021b2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	baa080e7          	jalr	-1110(ra) # 80000d5e <acquire>
  p->state = RUNNABLE;
    800021bc:	478d                	li	a5,3
    800021be:	cc9c                	sw	a5,24(s1)
  sched();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	f0a080e7          	jalr	-246(ra) # 800020ca <sched>
  release(&p->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	c48080e7          	jalr	-952(ra) # 80000e12 <release>
}
    800021d2:	60e2                	ld	ra,24(sp)
    800021d4:	6442                	ld	s0,16(sp)
    800021d6:	64a2                	ld	s1,8(sp)
    800021d8:	6105                	addi	sp,sp,32
    800021da:	8082                	ret

00000000800021dc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021dc:	7179                	addi	sp,sp,-48
    800021de:	f406                	sd	ra,40(sp)
    800021e0:	f022                	sd	s0,32(sp)
    800021e2:	ec26                	sd	s1,24(sp)
    800021e4:	e84a                	sd	s2,16(sp)
    800021e6:	e44e                	sd	s3,8(sp)
    800021e8:	1800                	addi	s0,sp,48
    800021ea:	89aa                	mv	s3,a0
    800021ec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	946080e7          	jalr	-1722(ra) # 80001b34 <myproc>
    800021f6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	b66080e7          	jalr	-1178(ra) # 80000d5e <acquire>
  release(lk);
    80002200:	854a                	mv	a0,s2
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	c10080e7          	jalr	-1008(ra) # 80000e12 <release>

  // Go to sleep.
  p->chan = chan;
    8000220a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000220e:	4789                	li	a5,2
    80002210:	cc9c                	sw	a5,24(s1)

  sched();
    80002212:	00000097          	auipc	ra,0x0
    80002216:	eb8080e7          	jalr	-328(ra) # 800020ca <sched>

  // Tidy up.
  p->chan = 0;
    8000221a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	bf2080e7          	jalr	-1038(ra) # 80000e12 <release>
  acquire(lk);
    80002228:	854a                	mv	a0,s2
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	b34080e7          	jalr	-1228(ra) # 80000d5e <acquire>
}
    80002232:	70a2                	ld	ra,40(sp)
    80002234:	7402                	ld	s0,32(sp)
    80002236:	64e2                	ld	s1,24(sp)
    80002238:	6942                	ld	s2,16(sp)
    8000223a:	69a2                	ld	s3,8(sp)
    8000223c:	6145                	addi	sp,sp,48
    8000223e:	8082                	ret

0000000080002240 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002240:	7139                	addi	sp,sp,-64
    80002242:	fc06                	sd	ra,56(sp)
    80002244:	f822                	sd	s0,48(sp)
    80002246:	f426                	sd	s1,40(sp)
    80002248:	f04a                	sd	s2,32(sp)
    8000224a:	ec4e                	sd	s3,24(sp)
    8000224c:	e852                	sd	s4,16(sp)
    8000224e:	e456                	sd	s5,8(sp)
    80002250:	0080                	addi	s0,sp,64
    80002252:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002254:	0000f497          	auipc	s1,0xf
    80002258:	59c48493          	addi	s1,s1,1436 # 800117f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000225c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000225e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002260:	00015917          	auipc	s2,0x15
    80002264:	f9090913          	addi	s2,s2,-112 # 800171f0 <tickslock>
    80002268:	a811                	j	8000227c <wakeup+0x3c>
      }
      release(&p->lock);
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	ba6080e7          	jalr	-1114(ra) # 80000e12 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002274:	16848493          	addi	s1,s1,360
    80002278:	03248663          	beq	s1,s2,800022a4 <wakeup+0x64>
    if(p != myproc()){
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	8b8080e7          	jalr	-1864(ra) # 80001b34 <myproc>
    80002284:	fea488e3          	beq	s1,a0,80002274 <wakeup+0x34>
      acquire(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	ad4080e7          	jalr	-1324(ra) # 80000d5e <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002292:	4c9c                	lw	a5,24(s1)
    80002294:	fd379be3          	bne	a5,s3,8000226a <wakeup+0x2a>
    80002298:	709c                	ld	a5,32(s1)
    8000229a:	fd4798e3          	bne	a5,s4,8000226a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000229e:	0154ac23          	sw	s5,24(s1)
    800022a2:	b7e1                	j	8000226a <wakeup+0x2a>
    }
  }
}
    800022a4:	70e2                	ld	ra,56(sp)
    800022a6:	7442                	ld	s0,48(sp)
    800022a8:	74a2                	ld	s1,40(sp)
    800022aa:	7902                	ld	s2,32(sp)
    800022ac:	69e2                	ld	s3,24(sp)
    800022ae:	6a42                	ld	s4,16(sp)
    800022b0:	6aa2                	ld	s5,8(sp)
    800022b2:	6121                	addi	sp,sp,64
    800022b4:	8082                	ret

00000000800022b6 <reparent>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	e052                	sd	s4,0(sp)
    800022c4:	1800                	addi	s0,sp,48
    800022c6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c8:	0000f497          	auipc	s1,0xf
    800022cc:	52848493          	addi	s1,s1,1320 # 800117f0 <proc>
      pp->parent = initproc;
    800022d0:	00006a17          	auipc	s4,0x6
    800022d4:	628a0a13          	addi	s4,s4,1576 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d8:	00015997          	auipc	s3,0x15
    800022dc:	f1898993          	addi	s3,s3,-232 # 800171f0 <tickslock>
    800022e0:	a029                	j	800022ea <reparent+0x34>
    800022e2:	16848493          	addi	s1,s1,360
    800022e6:	01348d63          	beq	s1,s3,80002300 <reparent+0x4a>
    if(pp->parent == p){
    800022ea:	7c9c                	ld	a5,56(s1)
    800022ec:	ff279be3          	bne	a5,s2,800022e2 <reparent+0x2c>
      pp->parent = initproc;
    800022f0:	000a3503          	ld	a0,0(s4)
    800022f4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	f4a080e7          	jalr	-182(ra) # 80002240 <wakeup>
    800022fe:	b7d5                	j	800022e2 <reparent+0x2c>
}
    80002300:	70a2                	ld	ra,40(sp)
    80002302:	7402                	ld	s0,32(sp)
    80002304:	64e2                	ld	s1,24(sp)
    80002306:	6942                	ld	s2,16(sp)
    80002308:	69a2                	ld	s3,8(sp)
    8000230a:	6a02                	ld	s4,0(sp)
    8000230c:	6145                	addi	sp,sp,48
    8000230e:	8082                	ret

0000000080002310 <exit>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	e052                	sd	s4,0(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002322:	00000097          	auipc	ra,0x0
    80002326:	812080e7          	jalr	-2030(ra) # 80001b34 <myproc>
    8000232a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000232c:	00006797          	auipc	a5,0x6
    80002330:	5cc7b783          	ld	a5,1484(a5) # 800088f8 <initproc>
    80002334:	0d050493          	addi	s1,a0,208
    80002338:	15050913          	addi	s2,a0,336
    8000233c:	02a79363          	bne	a5,a0,80002362 <exit+0x52>
    panic("init exiting");
    80002340:	00006517          	auipc	a0,0x6
    80002344:	f5050513          	addi	a0,a0,-176 # 80008290 <digits+0x220>
    80002348:	ffffe097          	auipc	ra,0xffffe
    8000234c:	37e080e7          	jalr	894(ra) # 800006c6 <panic>
      fileclose(f);
    80002350:	00002097          	auipc	ra,0x2
    80002354:	428080e7          	jalr	1064(ra) # 80004778 <fileclose>
      p->ofile[fd] = 0;
    80002358:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000235c:	04a1                	addi	s1,s1,8
    8000235e:	01248563          	beq	s1,s2,80002368 <exit+0x58>
    if(p->ofile[fd]){
    80002362:	6088                	ld	a0,0(s1)
    80002364:	f575                	bnez	a0,80002350 <exit+0x40>
    80002366:	bfdd                	j	8000235c <exit+0x4c>
  begin_op();
    80002368:	00002097          	auipc	ra,0x2
    8000236c:	f44080e7          	jalr	-188(ra) # 800042ac <begin_op>
  iput(p->cwd);
    80002370:	1509b503          	ld	a0,336(s3)
    80002374:	00001097          	auipc	ra,0x1
    80002378:	730080e7          	jalr	1840(ra) # 80003aa4 <iput>
  end_op();
    8000237c:	00002097          	auipc	ra,0x2
    80002380:	fb0080e7          	jalr	-80(ra) # 8000432c <end_op>
  p->cwd = 0;
    80002384:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002388:	0000f497          	auipc	s1,0xf
    8000238c:	05048493          	addi	s1,s1,80 # 800113d8 <wait_lock>
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	9cc080e7          	jalr	-1588(ra) # 80000d5e <acquire>
  reparent(p);
    8000239a:	854e                	mv	a0,s3
    8000239c:	00000097          	auipc	ra,0x0
    800023a0:	f1a080e7          	jalr	-230(ra) # 800022b6 <reparent>
  wakeup(p->parent);
    800023a4:	0389b503          	ld	a0,56(s3)
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	e98080e7          	jalr	-360(ra) # 80002240 <wakeup>
  acquire(&p->lock);
    800023b0:	854e                	mv	a0,s3
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	9ac080e7          	jalr	-1620(ra) # 80000d5e <acquire>
  p->xstate = status;
    800023ba:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023be:	4795                	li	a5,5
    800023c0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	a4c080e7          	jalr	-1460(ra) # 80000e12 <release>
  sched();
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	cfc080e7          	jalr	-772(ra) # 800020ca <sched>
  panic("zombie exit");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	eca50513          	addi	a0,a0,-310 # 800082a0 <digits+0x230>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	2e8080e7          	jalr	744(ra) # 800006c6 <panic>

00000000800023e6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e6:	7179                	addi	sp,sp,-48
    800023e8:	f406                	sd	ra,40(sp)
    800023ea:	f022                	sd	s0,32(sp)
    800023ec:	ec26                	sd	s1,24(sp)
    800023ee:	e84a                	sd	s2,16(sp)
    800023f0:	e44e                	sd	s3,8(sp)
    800023f2:	1800                	addi	s0,sp,48
    800023f4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f6:	0000f497          	auipc	s1,0xf
    800023fa:	3fa48493          	addi	s1,s1,1018 # 800117f0 <proc>
    800023fe:	00015997          	auipc	s3,0x15
    80002402:	df298993          	addi	s3,s3,-526 # 800171f0 <tickslock>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	956080e7          	jalr	-1706(ra) # 80000d5e <acquire>
    if(p->pid == pid){
    80002410:	589c                	lw	a5,48(s1)
    80002412:	01278d63          	beq	a5,s2,8000242c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	9fa080e7          	jalr	-1542(ra) # 80000e12 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002420:	16848493          	addi	s1,s1,360
    80002424:	ff3491e3          	bne	s1,s3,80002406 <kill+0x20>
  }
  return -1;
    80002428:	557d                	li	a0,-1
    8000242a:	a829                	j	80002444 <kill+0x5e>
      p->killed = 1;
    8000242c:	4785                	li	a5,1
    8000242e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002430:	4c98                	lw	a4,24(s1)
    80002432:	4789                	li	a5,2
    80002434:	00f70f63          	beq	a4,a5,80002452 <kill+0x6c>
      release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	9d8080e7          	jalr	-1576(ra) # 80000e12 <release>
      return 0;
    80002442:	4501                	li	a0,0
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret
        p->state = RUNNABLE;
    80002452:	478d                	li	a5,3
    80002454:	cc9c                	sw	a5,24(s1)
    80002456:	b7cd                	j	80002438 <kill+0x52>

0000000080002458 <setkilled>:

void
setkilled(struct proc *p)
{
    80002458:	1101                	addi	sp,sp,-32
    8000245a:	ec06                	sd	ra,24(sp)
    8000245c:	e822                	sd	s0,16(sp)
    8000245e:	e426                	sd	s1,8(sp)
    80002460:	1000                	addi	s0,sp,32
    80002462:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	8fa080e7          	jalr	-1798(ra) # 80000d5e <acquire>
  p->killed = 1;
    8000246c:	4785                	li	a5,1
    8000246e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	9a0080e7          	jalr	-1632(ra) # 80000e12 <release>
}
    8000247a:	60e2                	ld	ra,24(sp)
    8000247c:	6442                	ld	s0,16(sp)
    8000247e:	64a2                	ld	s1,8(sp)
    80002480:	6105                	addi	sp,sp,32
    80002482:	8082                	ret

0000000080002484 <killed>:

int
killed(struct proc *p)
{
    80002484:	1101                	addi	sp,sp,-32
    80002486:	ec06                	sd	ra,24(sp)
    80002488:	e822                	sd	s0,16(sp)
    8000248a:	e426                	sd	s1,8(sp)
    8000248c:	e04a                	sd	s2,0(sp)
    8000248e:	1000                	addi	s0,sp,32
    80002490:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	8cc080e7          	jalr	-1844(ra) # 80000d5e <acquire>
  k = p->killed;
    8000249a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	972080e7          	jalr	-1678(ra) # 80000e12 <release>
  return k;
}
    800024a8:	854a                	mv	a0,s2
    800024aa:	60e2                	ld	ra,24(sp)
    800024ac:	6442                	ld	s0,16(sp)
    800024ae:	64a2                	ld	s1,8(sp)
    800024b0:	6902                	ld	s2,0(sp)
    800024b2:	6105                	addi	sp,sp,32
    800024b4:	8082                	ret

00000000800024b6 <wait>:
{
    800024b6:	715d                	addi	sp,sp,-80
    800024b8:	e486                	sd	ra,72(sp)
    800024ba:	e0a2                	sd	s0,64(sp)
    800024bc:	fc26                	sd	s1,56(sp)
    800024be:	f84a                	sd	s2,48(sp)
    800024c0:	f44e                	sd	s3,40(sp)
    800024c2:	f052                	sd	s4,32(sp)
    800024c4:	ec56                	sd	s5,24(sp)
    800024c6:	e85a                	sd	s6,16(sp)
    800024c8:	e45e                	sd	s7,8(sp)
    800024ca:	e062                	sd	s8,0(sp)
    800024cc:	0880                	addi	s0,sp,80
    800024ce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	664080e7          	jalr	1636(ra) # 80001b34 <myproc>
    800024d8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024da:	0000f517          	auipc	a0,0xf
    800024de:	efe50513          	addi	a0,a0,-258 # 800113d8 <wait_lock>
    800024e2:	fffff097          	auipc	ra,0xfffff
    800024e6:	87c080e7          	jalr	-1924(ra) # 80000d5e <acquire>
    havekids = 0;
    800024ea:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800024ec:	4a15                	li	s4,5
        havekids = 1;
    800024ee:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024f0:	00015997          	auipc	s3,0x15
    800024f4:	d0098993          	addi	s3,s3,-768 # 800171f0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024f8:	0000fc17          	auipc	s8,0xf
    800024fc:	ee0c0c13          	addi	s8,s8,-288 # 800113d8 <wait_lock>
    havekids = 0;
    80002500:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002502:	0000f497          	auipc	s1,0xf
    80002506:	2ee48493          	addi	s1,s1,750 # 800117f0 <proc>
    8000250a:	a0bd                	j	80002578 <wait+0xc2>
          pid = pp->pid;
    8000250c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002510:	000b0e63          	beqz	s6,8000252c <wait+0x76>
    80002514:	4691                	li	a3,4
    80002516:	02c48613          	addi	a2,s1,44
    8000251a:	85da                	mv	a1,s6
    8000251c:	05093503          	ld	a0,80(s2)
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	2d0080e7          	jalr	720(ra) # 800017f0 <copyout>
    80002528:	02054563          	bltz	a0,80002552 <wait+0x9c>
          freeproc(pp);
    8000252c:	8526                	mv	a0,s1
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	7b8080e7          	jalr	1976(ra) # 80001ce6 <freeproc>
          release(&pp->lock);
    80002536:	8526                	mv	a0,s1
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	8da080e7          	jalr	-1830(ra) # 80000e12 <release>
          release(&wait_lock);
    80002540:	0000f517          	auipc	a0,0xf
    80002544:	e9850513          	addi	a0,a0,-360 # 800113d8 <wait_lock>
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	8ca080e7          	jalr	-1846(ra) # 80000e12 <release>
          return pid;
    80002550:	a0b5                	j	800025bc <wait+0x106>
            release(&pp->lock);
    80002552:	8526                	mv	a0,s1
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	8be080e7          	jalr	-1858(ra) # 80000e12 <release>
            release(&wait_lock);
    8000255c:	0000f517          	auipc	a0,0xf
    80002560:	e7c50513          	addi	a0,a0,-388 # 800113d8 <wait_lock>
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	8ae080e7          	jalr	-1874(ra) # 80000e12 <release>
            return -1;
    8000256c:	59fd                	li	s3,-1
    8000256e:	a0b9                	j	800025bc <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002570:	16848493          	addi	s1,s1,360
    80002574:	03348463          	beq	s1,s3,8000259c <wait+0xe6>
      if(pp->parent == p){
    80002578:	7c9c                	ld	a5,56(s1)
    8000257a:	ff279be3          	bne	a5,s2,80002570 <wait+0xba>
        acquire(&pp->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	7de080e7          	jalr	2014(ra) # 80000d5e <acquire>
        if(pp->state == ZOMBIE){
    80002588:	4c9c                	lw	a5,24(s1)
    8000258a:	f94781e3          	beq	a5,s4,8000250c <wait+0x56>
        release(&pp->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	882080e7          	jalr	-1918(ra) # 80000e12 <release>
        havekids = 1;
    80002598:	8756                	mv	a4,s5
    8000259a:	bfd9                	j	80002570 <wait+0xba>
    if(!havekids || killed(p)){
    8000259c:	c719                	beqz	a4,800025aa <wait+0xf4>
    8000259e:	854a                	mv	a0,s2
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	ee4080e7          	jalr	-284(ra) # 80002484 <killed>
    800025a8:	c51d                	beqz	a0,800025d6 <wait+0x120>
      release(&wait_lock);
    800025aa:	0000f517          	auipc	a0,0xf
    800025ae:	e2e50513          	addi	a0,a0,-466 # 800113d8 <wait_lock>
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	860080e7          	jalr	-1952(ra) # 80000e12 <release>
      return -1;
    800025ba:	59fd                	li	s3,-1
}
    800025bc:	854e                	mv	a0,s3
    800025be:	60a6                	ld	ra,72(sp)
    800025c0:	6406                	ld	s0,64(sp)
    800025c2:	74e2                	ld	s1,56(sp)
    800025c4:	7942                	ld	s2,48(sp)
    800025c6:	79a2                	ld	s3,40(sp)
    800025c8:	7a02                	ld	s4,32(sp)
    800025ca:	6ae2                	ld	s5,24(sp)
    800025cc:	6b42                	ld	s6,16(sp)
    800025ce:	6ba2                	ld	s7,8(sp)
    800025d0:	6c02                	ld	s8,0(sp)
    800025d2:	6161                	addi	sp,sp,80
    800025d4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025d6:	85e2                	mv	a1,s8
    800025d8:	854a                	mv	a0,s2
    800025da:	00000097          	auipc	ra,0x0
    800025de:	c02080e7          	jalr	-1022(ra) # 800021dc <sleep>
    havekids = 0;
    800025e2:	bf39                	j	80002500 <wait+0x4a>

00000000800025e4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025e4:	7179                	addi	sp,sp,-48
    800025e6:	f406                	sd	ra,40(sp)
    800025e8:	f022                	sd	s0,32(sp)
    800025ea:	ec26                	sd	s1,24(sp)
    800025ec:	e84a                	sd	s2,16(sp)
    800025ee:	e44e                	sd	s3,8(sp)
    800025f0:	e052                	sd	s4,0(sp)
    800025f2:	1800                	addi	s0,sp,48
    800025f4:	84aa                	mv	s1,a0
    800025f6:	892e                	mv	s2,a1
    800025f8:	89b2                	mv	s3,a2
    800025fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	538080e7          	jalr	1336(ra) # 80001b34 <myproc>
  if(user_dst){
    80002604:	c08d                	beqz	s1,80002626 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002606:	86d2                	mv	a3,s4
    80002608:	864e                	mv	a2,s3
    8000260a:	85ca                	mv	a1,s2
    8000260c:	6928                	ld	a0,80(a0)
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	1e2080e7          	jalr	482(ra) # 800017f0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002616:	70a2                	ld	ra,40(sp)
    80002618:	7402                	ld	s0,32(sp)
    8000261a:	64e2                	ld	s1,24(sp)
    8000261c:	6942                	ld	s2,16(sp)
    8000261e:	69a2                	ld	s3,8(sp)
    80002620:	6a02                	ld	s4,0(sp)
    80002622:	6145                	addi	sp,sp,48
    80002624:	8082                	ret
    memmove((char *)dst, src, len);
    80002626:	000a061b          	sext.w	a2,s4
    8000262a:	85ce                	mv	a1,s3
    8000262c:	854a                	mv	a0,s2
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	888080e7          	jalr	-1912(ra) # 80000eb6 <memmove>
    return 0;
    80002636:	8526                	mv	a0,s1
    80002638:	bff9                	j	80002616 <either_copyout+0x32>

000000008000263a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000263a:	7179                	addi	sp,sp,-48
    8000263c:	f406                	sd	ra,40(sp)
    8000263e:	f022                	sd	s0,32(sp)
    80002640:	ec26                	sd	s1,24(sp)
    80002642:	e84a                	sd	s2,16(sp)
    80002644:	e44e                	sd	s3,8(sp)
    80002646:	e052                	sd	s4,0(sp)
    80002648:	1800                	addi	s0,sp,48
    8000264a:	892a                	mv	s2,a0
    8000264c:	84ae                	mv	s1,a1
    8000264e:	89b2                	mv	s3,a2
    80002650:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	4e2080e7          	jalr	1250(ra) # 80001b34 <myproc>
  if(user_src){
    8000265a:	c08d                	beqz	s1,8000267c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000265c:	86d2                	mv	a3,s4
    8000265e:	864e                	mv	a2,s3
    80002660:	85ca                	mv	a1,s2
    80002662:	6928                	ld	a0,80(a0)
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	218080e7          	jalr	536(ra) # 8000187c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000266c:	70a2                	ld	ra,40(sp)
    8000266e:	7402                	ld	s0,32(sp)
    80002670:	64e2                	ld	s1,24(sp)
    80002672:	6942                	ld	s2,16(sp)
    80002674:	69a2                	ld	s3,8(sp)
    80002676:	6a02                	ld	s4,0(sp)
    80002678:	6145                	addi	sp,sp,48
    8000267a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000267c:	000a061b          	sext.w	a2,s4
    80002680:	85ce                	mv	a1,s3
    80002682:	854a                	mv	a0,s2
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	832080e7          	jalr	-1998(ra) # 80000eb6 <memmove>
    return 0;
    8000268c:	8526                	mv	a0,s1
    8000268e:	bff9                	j	8000266c <either_copyin+0x32>

0000000080002690 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002690:	715d                	addi	sp,sp,-80
    80002692:	e486                	sd	ra,72(sp)
    80002694:	e0a2                	sd	s0,64(sp)
    80002696:	fc26                	sd	s1,56(sp)
    80002698:	f84a                	sd	s2,48(sp)
    8000269a:	f44e                	sd	s3,40(sp)
    8000269c:	f052                	sd	s4,32(sp)
    8000269e:	ec56                	sd	s5,24(sp)
    800026a0:	e85a                	sd	s6,16(sp)
    800026a2:	e45e                	sd	s7,8(sp)
    800026a4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026a6:	00006517          	auipc	a0,0x6
    800026aa:	a5250513          	addi	a0,a0,-1454 # 800080f8 <digits+0x88>
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	062080e7          	jalr	98(ra) # 80000710 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b6:	0000f497          	auipc	s1,0xf
    800026ba:	29248493          	addi	s1,s1,658 # 80011948 <proc+0x158>
    800026be:	00015917          	auipc	s2,0x15
    800026c2:	c8a90913          	addi	s2,s2,-886 # 80017348 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026c8:	00006997          	auipc	s3,0x6
    800026cc:	be898993          	addi	s3,s3,-1048 # 800082b0 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800026d0:	00006a97          	auipc	s5,0x6
    800026d4:	be8a8a93          	addi	s5,s5,-1048 # 800082b8 <digits+0x248>
    printf("\n");
    800026d8:	00006a17          	auipc	s4,0x6
    800026dc:	a20a0a13          	addi	s4,s4,-1504 # 800080f8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e0:	00006b97          	auipc	s7,0x6
    800026e4:	c18b8b93          	addi	s7,s7,-1000 # 800082f8 <states.0>
    800026e8:	a00d                	j	8000270a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026ea:	ed86a583          	lw	a1,-296(a3)
    800026ee:	8556                	mv	a0,s5
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	020080e7          	jalr	32(ra) # 80000710 <printf>
    printf("\n");
    800026f8:	8552                	mv	a0,s4
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	016080e7          	jalr	22(ra) # 80000710 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002702:	16848493          	addi	s1,s1,360
    80002706:	03248163          	beq	s1,s2,80002728 <procdump+0x98>
    if(p->state == UNUSED)
    8000270a:	86a6                	mv	a3,s1
    8000270c:	ec04a783          	lw	a5,-320(s1)
    80002710:	dbed                	beqz	a5,80002702 <procdump+0x72>
      state = "???";
    80002712:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002714:	fcfb6be3          	bltu	s6,a5,800026ea <procdump+0x5a>
    80002718:	1782                	slli	a5,a5,0x20
    8000271a:	9381                	srli	a5,a5,0x20
    8000271c:	078e                	slli	a5,a5,0x3
    8000271e:	97de                	add	a5,a5,s7
    80002720:	6390                	ld	a2,0(a5)
    80002722:	f661                	bnez	a2,800026ea <procdump+0x5a>
      state = "???";
    80002724:	864e                	mv	a2,s3
    80002726:	b7d1                	j	800026ea <procdump+0x5a>
  }
}
    80002728:	60a6                	ld	ra,72(sp)
    8000272a:	6406                	ld	s0,64(sp)
    8000272c:	74e2                	ld	s1,56(sp)
    8000272e:	7942                	ld	s2,48(sp)
    80002730:	79a2                	ld	s3,40(sp)
    80002732:	7a02                	ld	s4,32(sp)
    80002734:	6ae2                	ld	s5,24(sp)
    80002736:	6b42                	ld	s6,16(sp)
    80002738:	6ba2                	ld	s7,8(sp)
    8000273a:	6161                	addi	sp,sp,80
    8000273c:	8082                	ret

000000008000273e <top>:

void
top(struct top *t)
{
    8000273e:	715d                	addi	sp,sp,-80
    80002740:	e486                	sd	ra,72(sp)
    80002742:	e0a2                	sd	s0,64(sp)
    80002744:	fc26                	sd	s1,56(sp)
    80002746:	f84a                	sd	s2,48(sp)
    80002748:	f44e                	sd	s3,40(sp)
    8000274a:	f052                	sd	s4,32(sp)
    8000274c:	ec56                	sd	s5,24(sp)
    8000274e:	e85a                	sd	s6,16(sp)
    80002750:	e45e                	sd	s7,8(sp)
    80002752:	0880                	addi	s0,sp,80
    80002754:	892a                	mv	s2,a0
    struct proc *p;
    t->total = 0;
    80002756:	00052223          	sw	zero,4(a0)
    t->running = 0;
    8000275a:	00052023          	sw	zero,0(a0)
    t->waiting = 0;
    8000275e:	00052423          	sw	zero,8(a0)

    for(p = proc; p < &proc[NPROC]; p++){
    80002762:	0000f497          	auipc	s1,0xf
    80002766:	1e648493          	addi	s1,s1,486 # 80011948 <proc+0x158>
    8000276a:	00015a17          	auipc	s4,0x15
    8000276e:	bdea0a13          	addi	s4,s4,-1058 # 80017348 <bcache+0x140>

        t->info[t->total].pid = p->pid;
        if (p->parent != 0) {
            t->info[t->total].ppid = p->parent->pid;
        } else {
            t->info[t->total].ppid = 0;
    80002772:	4b01                	li	s6,0
        }
        t->info[t->total].state = p->state;
        strncpy(t->info[t->total].name, p->name, 16);

        t->total++;
        if (p->state == RUNNING) {
    80002774:	4a91                	li	s5,4
            t->running++;
        } else if (p->state == SLEEPING) {
    80002776:	4b89                	li	s7,2
    80002778:	a811                	j	8000278c <top+0x4e>
            t->running++;
    8000277a:	00092783          	lw	a5,0(s2)
    8000277e:	2785                	addiw	a5,a5,1
    80002780:	00f92023          	sw	a5,0(s2)
    for(p = proc; p < &proc[NPROC]; p++){
    80002784:	16848493          	addi	s1,s1,360
    80002788:	07448b63          	beq	s1,s4,800027fe <top+0xc0>
        if(p->state == UNUSED)
    8000278c:	89a6                	mv	s3,s1
    8000278e:	ec04a783          	lw	a5,-320(s1)
    80002792:	dbed                	beqz	a5,80002784 <top+0x46>
        t->info[t->total].pid = p->pid;
    80002794:	00492503          	lw	a0,4(s2)
    80002798:	ed84a783          	lw	a5,-296(s1)
    8000279c:	00351713          	slli	a4,a0,0x3
    800027a0:	8f09                	sub	a4,a4,a0
    800027a2:	070a                	slli	a4,a4,0x2
    800027a4:	974a                	add	a4,a4,s2
    800027a6:	cf5c                	sw	a5,28(a4)
        if (p->parent != 0) {
    800027a8:	ee04b783          	ld	a5,-288(s1)
            t->info[t->total].ppid = 0;
    800027ac:	86da                	mv	a3,s6
        if (p->parent != 0) {
    800027ae:	c391                	beqz	a5,800027b2 <top+0x74>
            t->info[t->total].ppid = p->parent->pid;
    800027b0:	5b94                	lw	a3,48(a5)
    800027b2:	00351793          	slli	a5,a0,0x3
    800027b6:	40a78733          	sub	a4,a5,a0
    800027ba:	070a                	slli	a4,a4,0x2
    800027bc:	974a                	add	a4,a4,s2
    800027be:	d314                	sw	a3,32(a4)
        t->info[t->total].state = p->state;
    800027c0:	ec09a683          	lw	a3,-320(s3)
    800027c4:	d354                	sw	a3,36(a4)
        strncpy(t->info[t->total].name, p->name, 16);
    800027c6:	40a78533          	sub	a0,a5,a0
    800027ca:	050a                	slli	a0,a0,0x2
    800027cc:	0531                	addi	a0,a0,12
    800027ce:	4641                	li	a2,16
    800027d0:	85ce                	mv	a1,s3
    800027d2:	954a                	add	a0,a0,s2
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	792080e7          	jalr	1938(ra) # 80000f66 <strncpy>
        t->total++;
    800027dc:	00492783          	lw	a5,4(s2)
    800027e0:	2785                	addiw	a5,a5,1
    800027e2:	00f92223          	sw	a5,4(s2)
        if (p->state == RUNNING) {
    800027e6:	ec09a783          	lw	a5,-320(s3)
    800027ea:	f95788e3          	beq	a5,s5,8000277a <top+0x3c>
        } else if (p->state == SLEEPING) {
    800027ee:	f9779be3          	bne	a5,s7,80002784 <top+0x46>
            t->waiting++;
    800027f2:	00892783          	lw	a5,8(s2)
    800027f6:	2785                	addiw	a5,a5,1
    800027f8:	00f92423          	sw	a5,8(s2)
    800027fc:	b761                	j	80002784 <top+0x46>
        }
    }
}
    800027fe:	60a6                	ld	ra,72(sp)
    80002800:	6406                	ld	s0,64(sp)
    80002802:	74e2                	ld	s1,56(sp)
    80002804:	7942                	ld	s2,48(sp)
    80002806:	79a2                	ld	s3,40(sp)
    80002808:	7a02                	ld	s4,32(sp)
    8000280a:	6ae2                	ld	s5,24(sp)
    8000280c:	6b42                	ld	s6,16(sp)
    8000280e:	6ba2                	ld	s7,8(sp)
    80002810:	6161                	addi	sp,sp,80
    80002812:	8082                	ret

0000000080002814 <swtch>:
    80002814:	00153023          	sd	ra,0(a0)
    80002818:	00253423          	sd	sp,8(a0)
    8000281c:	e900                	sd	s0,16(a0)
    8000281e:	ed04                	sd	s1,24(a0)
    80002820:	03253023          	sd	s2,32(a0)
    80002824:	03353423          	sd	s3,40(a0)
    80002828:	03453823          	sd	s4,48(a0)
    8000282c:	03553c23          	sd	s5,56(a0)
    80002830:	05653023          	sd	s6,64(a0)
    80002834:	05753423          	sd	s7,72(a0)
    80002838:	05853823          	sd	s8,80(a0)
    8000283c:	05953c23          	sd	s9,88(a0)
    80002840:	07a53023          	sd	s10,96(a0)
    80002844:	07b53423          	sd	s11,104(a0)
    80002848:	0005b083          	ld	ra,0(a1)
    8000284c:	0085b103          	ld	sp,8(a1)
    80002850:	6980                	ld	s0,16(a1)
    80002852:	6d84                	ld	s1,24(a1)
    80002854:	0205b903          	ld	s2,32(a1)
    80002858:	0285b983          	ld	s3,40(a1)
    8000285c:	0305ba03          	ld	s4,48(a1)
    80002860:	0385ba83          	ld	s5,56(a1)
    80002864:	0405bb03          	ld	s6,64(a1)
    80002868:	0485bb83          	ld	s7,72(a1)
    8000286c:	0505bc03          	ld	s8,80(a1)
    80002870:	0585bc83          	ld	s9,88(a1)
    80002874:	0605bd03          	ld	s10,96(a1)
    80002878:	0685bd83          	ld	s11,104(a1)
    8000287c:	8082                	ret

000000008000287e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000287e:	1141                	addi	sp,sp,-16
    80002880:	e406                	sd	ra,8(sp)
    80002882:	e022                	sd	s0,0(sp)
    80002884:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002886:	00006597          	auipc	a1,0x6
    8000288a:	aa258593          	addi	a1,a1,-1374 # 80008328 <states.0+0x30>
    8000288e:	00015517          	auipc	a0,0x15
    80002892:	96250513          	addi	a0,a0,-1694 # 800171f0 <tickslock>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	438080e7          	jalr	1080(ra) # 80000cce <initlock>
}
    8000289e:	60a2                	ld	ra,8(sp)
    800028a0:	6402                	ld	s0,0(sp)
    800028a2:	0141                	addi	sp,sp,16
    800028a4:	8082                	ret

00000000800028a6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028a6:	1141                	addi	sp,sp,-16
    800028a8:	e422                	sd	s0,8(sp)
    800028aa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ac:	00003797          	auipc	a5,0x3
    800028b0:	51478793          	addi	a5,a5,1300 # 80005dc0 <kernelvec>
    800028b4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028b8:	6422                	ld	s0,8(sp)
    800028ba:	0141                	addi	sp,sp,16
    800028bc:	8082                	ret

00000000800028be <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028be:	1141                	addi	sp,sp,-16
    800028c0:	e406                	sd	ra,8(sp)
    800028c2:	e022                	sd	s0,0(sp)
    800028c4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	26e080e7          	jalr	622(ra) # 80001b34 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028d8:	00004617          	auipc	a2,0x4
    800028dc:	72860613          	addi	a2,a2,1832 # 80007000 <_trampoline>
    800028e0:	00004697          	auipc	a3,0x4
    800028e4:	72068693          	addi	a3,a3,1824 # 80007000 <_trampoline>
    800028e8:	8e91                	sub	a3,a3,a2
    800028ea:	040007b7          	lui	a5,0x4000
    800028ee:	17fd                	addi	a5,a5,-1
    800028f0:	07b2                	slli	a5,a5,0xc
    800028f2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028f8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028fa:	180026f3          	csrr	a3,satp
    800028fe:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002900:	6d38                	ld	a4,88(a0)
    80002902:	6134                	ld	a3,64(a0)
    80002904:	6585                	lui	a1,0x1
    80002906:	96ae                	add	a3,a3,a1
    80002908:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000290a:	6d38                	ld	a4,88(a0)
    8000290c:	00000697          	auipc	a3,0x0
    80002910:	13068693          	addi	a3,a3,304 # 80002a3c <usertrap>
    80002914:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002916:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002918:	8692                	mv	a3,tp
    8000291a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002920:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002924:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000292c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000292e:	6f18                	ld	a4,24(a4)
    80002930:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002934:	6928                	ld	a0,80(a0)
    80002936:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002938:	00004717          	auipc	a4,0x4
    8000293c:	76470713          	addi	a4,a4,1892 # 8000709c <userret>
    80002940:	8f11                	sub	a4,a4,a2
    80002942:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002944:	577d                	li	a4,-1
    80002946:	177e                	slli	a4,a4,0x3f
    80002948:	8d59                	or	a0,a0,a4
    8000294a:	9782                	jalr	a5
}
    8000294c:	60a2                	ld	ra,8(sp)
    8000294e:	6402                	ld	s0,0(sp)
    80002950:	0141                	addi	sp,sp,16
    80002952:	8082                	ret

0000000080002954 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002954:	1101                	addi	sp,sp,-32
    80002956:	ec06                	sd	ra,24(sp)
    80002958:	e822                	sd	s0,16(sp)
    8000295a:	e426                	sd	s1,8(sp)
    8000295c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000295e:	00015497          	auipc	s1,0x15
    80002962:	89248493          	addi	s1,s1,-1902 # 800171f0 <tickslock>
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	3f6080e7          	jalr	1014(ra) # 80000d5e <acquire>
  ticks++;
    80002970:	00006517          	auipc	a0,0x6
    80002974:	f9050513          	addi	a0,a0,-112 # 80008900 <ticks>
    80002978:	411c                	lw	a5,0(a0)
    8000297a:	2785                	addiw	a5,a5,1
    8000297c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	8c2080e7          	jalr	-1854(ra) # 80002240 <wakeup>
  release(&tickslock);
    80002986:	8526                	mv	a0,s1
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	48a080e7          	jalr	1162(ra) # 80000e12 <release>
}
    80002990:	60e2                	ld	ra,24(sp)
    80002992:	6442                	ld	s0,16(sp)
    80002994:	64a2                	ld	s1,8(sp)
    80002996:	6105                	addi	sp,sp,32
    80002998:	8082                	ret

000000008000299a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000299a:	1101                	addi	sp,sp,-32
    8000299c:	ec06                	sd	ra,24(sp)
    8000299e:	e822                	sd	s0,16(sp)
    800029a0:	e426                	sd	s1,8(sp)
    800029a2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029a8:	00074d63          	bltz	a4,800029c2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029ac:	57fd                	li	a5,-1
    800029ae:	17fe                	slli	a5,a5,0x3f
    800029b0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029b2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029b4:	06f70363          	beq	a4,a5,80002a1a <devintr+0x80>
  }
}
    800029b8:	60e2                	ld	ra,24(sp)
    800029ba:	6442                	ld	s0,16(sp)
    800029bc:	64a2                	ld	s1,8(sp)
    800029be:	6105                	addi	sp,sp,32
    800029c0:	8082                	ret
     (scause & 0xff) == 9){
    800029c2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029c6:	46a5                	li	a3,9
    800029c8:	fed792e3          	bne	a5,a3,800029ac <devintr+0x12>
    int irq = plic_claim();
    800029cc:	00003097          	auipc	ra,0x3
    800029d0:	4fc080e7          	jalr	1276(ra) # 80005ec8 <plic_claim>
    800029d4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029d6:	47a9                	li	a5,10
    800029d8:	02f50763          	beq	a0,a5,80002a06 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029dc:	4785                	li	a5,1
    800029de:	02f50963          	beq	a0,a5,80002a10 <devintr+0x76>
    return 1;
    800029e2:	4505                	li	a0,1
    } else if(irq){
    800029e4:	d8f1                	beqz	s1,800029b8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029e6:	85a6                	mv	a1,s1
    800029e8:	00006517          	auipc	a0,0x6
    800029ec:	94850513          	addi	a0,a0,-1720 # 80008330 <states.0+0x38>
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	d20080e7          	jalr	-736(ra) # 80000710 <printf>
      plic_complete(irq);
    800029f8:	8526                	mv	a0,s1
    800029fa:	00003097          	auipc	ra,0x3
    800029fe:	4f2080e7          	jalr	1266(ra) # 80005eec <plic_complete>
    return 1;
    80002a02:	4505                	li	a0,1
    80002a04:	bf55                	j	800029b8 <devintr+0x1e>
      uartintr();
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	11c080e7          	jalr	284(ra) # 80000b22 <uartintr>
    80002a0e:	b7ed                	j	800029f8 <devintr+0x5e>
      virtio_disk_intr();
    80002a10:	00004097          	auipc	ra,0x4
    80002a14:	9a8080e7          	jalr	-1624(ra) # 800063b8 <virtio_disk_intr>
    80002a18:	b7c5                	j	800029f8 <devintr+0x5e>
    if(cpuid() == 0){
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	0ee080e7          	jalr	238(ra) # 80001b08 <cpuid>
    80002a22:	c901                	beqz	a0,80002a32 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a24:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a2a:	14479073          	csrw	sip,a5
    return 2;
    80002a2e:	4509                	li	a0,2
    80002a30:	b761                	j	800029b8 <devintr+0x1e>
      clockintr();
    80002a32:	00000097          	auipc	ra,0x0
    80002a36:	f22080e7          	jalr	-222(ra) # 80002954 <clockintr>
    80002a3a:	b7ed                	j	80002a24 <devintr+0x8a>

0000000080002a3c <usertrap>:
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	e04a                	sd	s2,0(sp)
    80002a46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a48:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a4c:	1007f793          	andi	a5,a5,256
    80002a50:	e3b1                	bnez	a5,80002a94 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a52:	00003797          	auipc	a5,0x3
    80002a56:	36e78793          	addi	a5,a5,878 # 80005dc0 <kernelvec>
    80002a5a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	0d6080e7          	jalr	214(ra) # 80001b34 <myproc>
    80002a66:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a68:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6a:	14102773          	csrr	a4,sepc
    80002a6e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a70:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a74:	47a1                	li	a5,8
    80002a76:	02f70763          	beq	a4,a5,80002aa4 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	f20080e7          	jalr	-224(ra) # 8000299a <devintr>
    80002a82:	892a                	mv	s2,a0
    80002a84:	c151                	beqz	a0,80002b08 <usertrap+0xcc>
  if(killed(p))
    80002a86:	8526                	mv	a0,s1
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	9fc080e7          	jalr	-1540(ra) # 80002484 <killed>
    80002a90:	c929                	beqz	a0,80002ae2 <usertrap+0xa6>
    80002a92:	a099                	j	80002ad8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	8bc50513          	addi	a0,a0,-1860 # 80008350 <states.0+0x58>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	c2a080e7          	jalr	-982(ra) # 800006c6 <panic>
    if(killed(p))
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	9e0080e7          	jalr	-1568(ra) # 80002484 <killed>
    80002aac:	e921                	bnez	a0,80002afc <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002aae:	6cb8                	ld	a4,88(s1)
    80002ab0:	6f1c                	ld	a5,24(a4)
    80002ab2:	0791                	addi	a5,a5,4
    80002ab4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002abe:	10079073          	csrw	sstatus,a5
    syscall();
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	2d4080e7          	jalr	724(ra) # 80002d96 <syscall>
  if(killed(p))
    80002aca:	8526                	mv	a0,s1
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	9b8080e7          	jalr	-1608(ra) # 80002484 <killed>
    80002ad4:	c911                	beqz	a0,80002ae8 <usertrap+0xac>
    80002ad6:	4901                	li	s2,0
    exit(-1);
    80002ad8:	557d                	li	a0,-1
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	836080e7          	jalr	-1994(ra) # 80002310 <exit>
  if(which_dev == 2)
    80002ae2:	4789                	li	a5,2
    80002ae4:	04f90f63          	beq	s2,a5,80002b42 <usertrap+0x106>
  usertrapret();
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	dd6080e7          	jalr	-554(ra) # 800028be <usertrapret>
}
    80002af0:	60e2                	ld	ra,24(sp)
    80002af2:	6442                	ld	s0,16(sp)
    80002af4:	64a2                	ld	s1,8(sp)
    80002af6:	6902                	ld	s2,0(sp)
    80002af8:	6105                	addi	sp,sp,32
    80002afa:	8082                	ret
      exit(-1);
    80002afc:	557d                	li	a0,-1
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	812080e7          	jalr	-2030(ra) # 80002310 <exit>
    80002b06:	b765                	j	80002aae <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b0c:	5890                	lw	a2,48(s1)
    80002b0e:	00006517          	auipc	a0,0x6
    80002b12:	86250513          	addi	a0,a0,-1950 # 80008370 <states.0+0x78>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	bfa080e7          	jalr	-1030(ra) # 80000710 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b22:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b26:	00006517          	auipc	a0,0x6
    80002b2a:	87a50513          	addi	a0,a0,-1926 # 800083a0 <states.0+0xa8>
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	be2080e7          	jalr	-1054(ra) # 80000710 <printf>
    setkilled(p);
    80002b36:	8526                	mv	a0,s1
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	920080e7          	jalr	-1760(ra) # 80002458 <setkilled>
    80002b40:	b769                	j	80002aca <usertrap+0x8e>
    yield();
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	65e080e7          	jalr	1630(ra) # 800021a0 <yield>
    80002b4a:	bf79                	j	80002ae8 <usertrap+0xac>

0000000080002b4c <kerneltrap>:
{
    80002b4c:	7179                	addi	sp,sp,-48
    80002b4e:	f406                	sd	ra,40(sp)
    80002b50:	f022                	sd	s0,32(sp)
    80002b52:	ec26                	sd	s1,24(sp)
    80002b54:	e84a                	sd	s2,16(sp)
    80002b56:	e44e                	sd	s3,8(sp)
    80002b58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b62:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b66:	1004f793          	andi	a5,s1,256
    80002b6a:	cb85                	beqz	a5,80002b9a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b70:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b72:	ef85                	bnez	a5,80002baa <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	e26080e7          	jalr	-474(ra) # 8000299a <devintr>
    80002b7c:	cd1d                	beqz	a0,80002bba <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b7e:	4789                	li	a5,2
    80002b80:	06f50a63          	beq	a0,a5,80002bf4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b84:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b88:	10049073          	csrw	sstatus,s1
}
    80002b8c:	70a2                	ld	ra,40(sp)
    80002b8e:	7402                	ld	s0,32(sp)
    80002b90:	64e2                	ld	s1,24(sp)
    80002b92:	6942                	ld	s2,16(sp)
    80002b94:	69a2                	ld	s3,8(sp)
    80002b96:	6145                	addi	sp,sp,48
    80002b98:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	82650513          	addi	a0,a0,-2010 # 800083c0 <states.0+0xc8>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	b24080e7          	jalr	-1244(ra) # 800006c6 <panic>
    panic("kerneltrap: interrupts enabled");
    80002baa:	00006517          	auipc	a0,0x6
    80002bae:	83e50513          	addi	a0,a0,-1986 # 800083e8 <states.0+0xf0>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	b14080e7          	jalr	-1260(ra) # 800006c6 <panic>
    printf("scause %p\n", scause);
    80002bba:	85ce                	mv	a1,s3
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	84c50513          	addi	a0,a0,-1972 # 80008408 <states.0+0x110>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	b4c080e7          	jalr	-1204(ra) # 80000710 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bcc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bd4:	00006517          	auipc	a0,0x6
    80002bd8:	84450513          	addi	a0,a0,-1980 # 80008418 <states.0+0x120>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	b34080e7          	jalr	-1228(ra) # 80000710 <printf>
    panic("kerneltrap");
    80002be4:	00006517          	auipc	a0,0x6
    80002be8:	84c50513          	addi	a0,a0,-1972 # 80008430 <states.0+0x138>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	ada080e7          	jalr	-1318(ra) # 800006c6 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	f40080e7          	jalr	-192(ra) # 80001b34 <myproc>
    80002bfc:	d541                	beqz	a0,80002b84 <kerneltrap+0x38>
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	f36080e7          	jalr	-202(ra) # 80001b34 <myproc>
    80002c06:	4d18                	lw	a4,24(a0)
    80002c08:	4791                	li	a5,4
    80002c0a:	f6f71de3          	bne	a4,a5,80002b84 <kerneltrap+0x38>
    yield();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	592080e7          	jalr	1426(ra) # 800021a0 <yield>
    80002c16:	b7bd                	j	80002b84 <kerneltrap+0x38>

0000000080002c18 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c18:	1101                	addi	sp,sp,-32
    80002c1a:	ec06                	sd	ra,24(sp)
    80002c1c:	e822                	sd	s0,16(sp)
    80002c1e:	e426                	sd	s1,8(sp)
    80002c20:	1000                	addi	s0,sp,32
    80002c22:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	f10080e7          	jalr	-240(ra) # 80001b34 <myproc>
  switch (n) {
    80002c2c:	4795                	li	a5,5
    80002c2e:	0497e163          	bltu	a5,s1,80002c70 <argraw+0x58>
    80002c32:	048a                	slli	s1,s1,0x2
    80002c34:	00006717          	auipc	a4,0x6
    80002c38:	83470713          	addi	a4,a4,-1996 # 80008468 <states.0+0x170>
    80002c3c:	94ba                	add	s1,s1,a4
    80002c3e:	409c                	lw	a5,0(s1)
    80002c40:	97ba                	add	a5,a5,a4
    80002c42:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c44:	6d3c                	ld	a5,88(a0)
    80002c46:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6105                	addi	sp,sp,32
    80002c50:	8082                	ret
    return p->trapframe->a1;
    80002c52:	6d3c                	ld	a5,88(a0)
    80002c54:	7fa8                	ld	a0,120(a5)
    80002c56:	bfcd                	j	80002c48 <argraw+0x30>
    return p->trapframe->a2;
    80002c58:	6d3c                	ld	a5,88(a0)
    80002c5a:	63c8                	ld	a0,128(a5)
    80002c5c:	b7f5                	j	80002c48 <argraw+0x30>
    return p->trapframe->a3;
    80002c5e:	6d3c                	ld	a5,88(a0)
    80002c60:	67c8                	ld	a0,136(a5)
    80002c62:	b7dd                	j	80002c48 <argraw+0x30>
    return p->trapframe->a4;
    80002c64:	6d3c                	ld	a5,88(a0)
    80002c66:	6bc8                	ld	a0,144(a5)
    80002c68:	b7c5                	j	80002c48 <argraw+0x30>
    return p->trapframe->a5;
    80002c6a:	6d3c                	ld	a5,88(a0)
    80002c6c:	6fc8                	ld	a0,152(a5)
    80002c6e:	bfe9                	j	80002c48 <argraw+0x30>
  panic("argraw");
    80002c70:	00005517          	auipc	a0,0x5
    80002c74:	7d050513          	addi	a0,a0,2000 # 80008440 <states.0+0x148>
    80002c78:	ffffe097          	auipc	ra,0xffffe
    80002c7c:	a4e080e7          	jalr	-1458(ra) # 800006c6 <panic>

0000000080002c80 <fetchaddr>:
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	e04a                	sd	s2,0(sp)
    80002c8a:	1000                	addi	s0,sp,32
    80002c8c:	84aa                	mv	s1,a0
    80002c8e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	ea4080e7          	jalr	-348(ra) # 80001b34 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c98:	653c                	ld	a5,72(a0)
    80002c9a:	02f4f863          	bgeu	s1,a5,80002cca <fetchaddr+0x4a>
    80002c9e:	00848713          	addi	a4,s1,8
    80002ca2:	02e7e663          	bltu	a5,a4,80002cce <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ca6:	46a1                	li	a3,8
    80002ca8:	8626                	mv	a2,s1
    80002caa:	85ca                	mv	a1,s2
    80002cac:	6928                	ld	a0,80(a0)
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	bce080e7          	jalr	-1074(ra) # 8000187c <copyin>
    80002cb6:	00a03533          	snez	a0,a0
    80002cba:	40a00533          	neg	a0,a0
}
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	64a2                	ld	s1,8(sp)
    80002cc4:	6902                	ld	s2,0(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret
    return -1;
    80002cca:	557d                	li	a0,-1
    80002ccc:	bfcd                	j	80002cbe <fetchaddr+0x3e>
    80002cce:	557d                	li	a0,-1
    80002cd0:	b7fd                	j	80002cbe <fetchaddr+0x3e>

0000000080002cd2 <fetchstr>:
{
    80002cd2:	7179                	addi	sp,sp,-48
    80002cd4:	f406                	sd	ra,40(sp)
    80002cd6:	f022                	sd	s0,32(sp)
    80002cd8:	ec26                	sd	s1,24(sp)
    80002cda:	e84a                	sd	s2,16(sp)
    80002cdc:	e44e                	sd	s3,8(sp)
    80002cde:	1800                	addi	s0,sp,48
    80002ce0:	892a                	mv	s2,a0
    80002ce2:	84ae                	mv	s1,a1
    80002ce4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	e4e080e7          	jalr	-434(ra) # 80001b34 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cee:	86ce                	mv	a3,s3
    80002cf0:	864a                	mv	a2,s2
    80002cf2:	85a6                	mv	a1,s1
    80002cf4:	6928                	ld	a0,80(a0)
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	c14080e7          	jalr	-1004(ra) # 8000190a <copyinstr>
    80002cfe:	00054e63          	bltz	a0,80002d1a <fetchstr+0x48>
  return strlen(buf);
    80002d02:	8526                	mv	a0,s1
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	2d2080e7          	jalr	722(ra) # 80000fd6 <strlen>
}
    80002d0c:	70a2                	ld	ra,40(sp)
    80002d0e:	7402                	ld	s0,32(sp)
    80002d10:	64e2                	ld	s1,24(sp)
    80002d12:	6942                	ld	s2,16(sp)
    80002d14:	69a2                	ld	s3,8(sp)
    80002d16:	6145                	addi	sp,sp,48
    80002d18:	8082                	ret
    return -1;
    80002d1a:	557d                	li	a0,-1
    80002d1c:	bfc5                	j	80002d0c <fetchstr+0x3a>

0000000080002d1e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d1e:	1101                	addi	sp,sp,-32
    80002d20:	ec06                	sd	ra,24(sp)
    80002d22:	e822                	sd	s0,16(sp)
    80002d24:	e426                	sd	s1,8(sp)
    80002d26:	1000                	addi	s0,sp,32
    80002d28:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	eee080e7          	jalr	-274(ra) # 80002c18 <argraw>
    80002d32:	c088                	sw	a0,0(s1)
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
    80002d48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	ece080e7          	jalr	-306(ra) # 80002c18 <argraw>
    80002d52:	e088                	sd	a0,0(s1)
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret

0000000080002d5e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d5e:	7179                	addi	sp,sp,-48
    80002d60:	f406                	sd	ra,40(sp)
    80002d62:	f022                	sd	s0,32(sp)
    80002d64:	ec26                	sd	s1,24(sp)
    80002d66:	e84a                	sd	s2,16(sp)
    80002d68:	1800                	addi	s0,sp,48
    80002d6a:	84ae                	mv	s1,a1
    80002d6c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d6e:	fd840593          	addi	a1,s0,-40
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	fcc080e7          	jalr	-52(ra) # 80002d3e <argaddr>
  return fetchstr(addr, buf, max);
    80002d7a:	864a                	mv	a2,s2
    80002d7c:	85a6                	mv	a1,s1
    80002d7e:	fd843503          	ld	a0,-40(s0)
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	f50080e7          	jalr	-176(ra) # 80002cd2 <fetchstr>
}
    80002d8a:	70a2                	ld	ra,40(sp)
    80002d8c:	7402                	ld	s0,32(sp)
    80002d8e:	64e2                	ld	s1,24(sp)
    80002d90:	6942                	ld	s2,16(sp)
    80002d92:	6145                	addi	sp,sp,48
    80002d94:	8082                	ret

0000000080002d96 <syscall>:
[SYS_history] sys_history,
};

void
syscall(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	e426                	sd	s1,8(sp)
    80002d9e:	e04a                	sd	s2,0(sp)
    80002da0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	d92080e7          	jalr	-622(ra) # 80001b34 <myproc>
    80002daa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dac:	05853903          	ld	s2,88(a0)
    80002db0:	0a893783          	ld	a5,168(s2)
    80002db4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002db8:	37fd                	addiw	a5,a5,-1
    80002dba:	4759                	li	a4,22
    80002dbc:	00f76f63          	bltu	a4,a5,80002dda <syscall+0x44>
    80002dc0:	00369713          	slli	a4,a3,0x3
    80002dc4:	00005797          	auipc	a5,0x5
    80002dc8:	6bc78793          	addi	a5,a5,1724 # 80008480 <syscalls>
    80002dcc:	97ba                	add	a5,a5,a4
    80002dce:	639c                	ld	a5,0(a5)
    80002dd0:	c789                	beqz	a5,80002dda <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002dd2:	9782                	jalr	a5
    80002dd4:	06a93823          	sd	a0,112(s2)
    80002dd8:	a839                	j	80002df6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dda:	15848613          	addi	a2,s1,344
    80002dde:	588c                	lw	a1,48(s1)
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	66850513          	addi	a0,a0,1640 # 80008448 <states.0+0x150>
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	928080e7          	jalr	-1752(ra) # 80000710 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002df0:	6cbc                	ld	a5,88(s1)
    80002df2:	577d                	li	a4,-1
    80002df4:	fbb8                	sd	a4,112(a5)
  }
}
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	64a2                	ld	s1,8(sp)
    80002dfc:	6902                	ld	s2,0(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e02:	1101                	addi	sp,sp,-32
    80002e04:	ec06                	sd	ra,24(sp)
    80002e06:	e822                	sd	s0,16(sp)
    80002e08:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e0a:	fec40593          	addi	a1,s0,-20
    80002e0e:	4501                	li	a0,0
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	f0e080e7          	jalr	-242(ra) # 80002d1e <argint>
  exit(n);
    80002e18:	fec42503          	lw	a0,-20(s0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	4f4080e7          	jalr	1268(ra) # 80002310 <exit>
  return 0;  // not reached
}
    80002e24:	4501                	li	a0,0
    80002e26:	60e2                	ld	ra,24(sp)
    80002e28:	6442                	ld	s0,16(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e2e:	1141                	addi	sp,sp,-16
    80002e30:	e406                	sd	ra,8(sp)
    80002e32:	e022                	sd	s0,0(sp)
    80002e34:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	cfe080e7          	jalr	-770(ra) # 80001b34 <myproc>
}
    80002e3e:	5908                	lw	a0,48(a0)
    80002e40:	60a2                	ld	ra,8(sp)
    80002e42:	6402                	ld	s0,0(sp)
    80002e44:	0141                	addi	sp,sp,16
    80002e46:	8082                	ret

0000000080002e48 <sys_fork>:

uint64
sys_fork(void)
{
    80002e48:	1141                	addi	sp,sp,-16
    80002e4a:	e406                	sd	ra,8(sp)
    80002e4c:	e022                	sd	s0,0(sp)
    80002e4e:	0800                	addi	s0,sp,16
  return fork();
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	09a080e7          	jalr	154(ra) # 80001eea <fork>
}
    80002e58:	60a2                	ld	ra,8(sp)
    80002e5a:	6402                	ld	s0,0(sp)
    80002e5c:	0141                	addi	sp,sp,16
    80002e5e:	8082                	ret

0000000080002e60 <sys_wait>:

uint64
sys_wait(void)
{
    80002e60:	1101                	addi	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e68:	fe840593          	addi	a1,s0,-24
    80002e6c:	4501                	li	a0,0
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	ed0080e7          	jalr	-304(ra) # 80002d3e <argaddr>
  return wait(p);
    80002e76:	fe843503          	ld	a0,-24(s0)
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	63c080e7          	jalr	1596(ra) # 800024b6 <wait>
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret

0000000080002e8a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e8a:	7179                	addi	sp,sp,-48
    80002e8c:	f406                	sd	ra,40(sp)
    80002e8e:	f022                	sd	s0,32(sp)
    80002e90:	ec26                	sd	s1,24(sp)
    80002e92:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e94:	fdc40593          	addi	a1,s0,-36
    80002e98:	4501                	li	a0,0
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	e84080e7          	jalr	-380(ra) # 80002d1e <argint>
  addr = myproc()->sz;
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	c92080e7          	jalr	-878(ra) # 80001b34 <myproc>
    80002eaa:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002eac:	fdc42503          	lw	a0,-36(s0)
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	fde080e7          	jalr	-34(ra) # 80001e8e <growproc>
    80002eb8:	00054863          	bltz	a0,80002ec8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ebc:	8526                	mv	a0,s1
    80002ebe:	70a2                	ld	ra,40(sp)
    80002ec0:	7402                	ld	s0,32(sp)
    80002ec2:	64e2                	ld	s1,24(sp)
    80002ec4:	6145                	addi	sp,sp,48
    80002ec6:	8082                	ret
    return -1;
    80002ec8:	54fd                	li	s1,-1
    80002eca:	bfcd                	j	80002ebc <sys_sbrk+0x32>

0000000080002ecc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ecc:	7139                	addi	sp,sp,-64
    80002ece:	fc06                	sd	ra,56(sp)
    80002ed0:	f822                	sd	s0,48(sp)
    80002ed2:	f426                	sd	s1,40(sp)
    80002ed4:	f04a                	sd	s2,32(sp)
    80002ed6:	ec4e                	sd	s3,24(sp)
    80002ed8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002eda:	fcc40593          	addi	a1,s0,-52
    80002ede:	4501                	li	a0,0
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	e3e080e7          	jalr	-450(ra) # 80002d1e <argint>
  acquire(&tickslock);
    80002ee8:	00014517          	auipc	a0,0x14
    80002eec:	30850513          	addi	a0,a0,776 # 800171f0 <tickslock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	e6e080e7          	jalr	-402(ra) # 80000d5e <acquire>
  ticks0 = ticks;
    80002ef8:	00006917          	auipc	s2,0x6
    80002efc:	a0892903          	lw	s2,-1528(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002f00:	fcc42783          	lw	a5,-52(s0)
    80002f04:	cf9d                	beqz	a5,80002f42 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f06:	00014997          	auipc	s3,0x14
    80002f0a:	2ea98993          	addi	s3,s3,746 # 800171f0 <tickslock>
    80002f0e:	00006497          	auipc	s1,0x6
    80002f12:	9f248493          	addi	s1,s1,-1550 # 80008900 <ticks>
    if(killed(myproc())){
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	c1e080e7          	jalr	-994(ra) # 80001b34 <myproc>
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	566080e7          	jalr	1382(ra) # 80002484 <killed>
    80002f26:	ed15                	bnez	a0,80002f62 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f28:	85ce                	mv	a1,s3
    80002f2a:	8526                	mv	a0,s1
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	2b0080e7          	jalr	688(ra) # 800021dc <sleep>
  while(ticks - ticks0 < n){
    80002f34:	409c                	lw	a5,0(s1)
    80002f36:	412787bb          	subw	a5,a5,s2
    80002f3a:	fcc42703          	lw	a4,-52(s0)
    80002f3e:	fce7ece3          	bltu	a5,a4,80002f16 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f42:	00014517          	auipc	a0,0x14
    80002f46:	2ae50513          	addi	a0,a0,686 # 800171f0 <tickslock>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	ec8080e7          	jalr	-312(ra) # 80000e12 <release>
  return 0;
    80002f52:	4501                	li	a0,0
}
    80002f54:	70e2                	ld	ra,56(sp)
    80002f56:	7442                	ld	s0,48(sp)
    80002f58:	74a2                	ld	s1,40(sp)
    80002f5a:	7902                	ld	s2,32(sp)
    80002f5c:	69e2                	ld	s3,24(sp)
    80002f5e:	6121                	addi	sp,sp,64
    80002f60:	8082                	ret
      release(&tickslock);
    80002f62:	00014517          	auipc	a0,0x14
    80002f66:	28e50513          	addi	a0,a0,654 # 800171f0 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	ea8080e7          	jalr	-344(ra) # 80000e12 <release>
      return -1;
    80002f72:	557d                	li	a0,-1
    80002f74:	b7c5                	j	80002f54 <sys_sleep+0x88>

0000000080002f76 <sys_kill>:

uint64
sys_kill(void)
{
    80002f76:	1101                	addi	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f7e:	fec40593          	addi	a1,s0,-20
    80002f82:	4501                	li	a0,0
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	d9a080e7          	jalr	-614(ra) # 80002d1e <argint>
  return kill(pid);
    80002f8c:	fec42503          	lw	a0,-20(s0)
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	456080e7          	jalr	1110(ra) # 800023e6 <kill>
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	6105                	addi	sp,sp,32
    80002f9e:	8082                	ret

0000000080002fa0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	e426                	sd	s1,8(sp)
    80002fa8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	24650513          	addi	a0,a0,582 # 800171f0 <tickslock>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	dac080e7          	jalr	-596(ra) # 80000d5e <acquire>
  xticks = ticks;
    80002fba:	00006497          	auipc	s1,0x6
    80002fbe:	9464a483          	lw	s1,-1722(s1) # 80008900 <ticks>
  release(&tickslock);
    80002fc2:	00014517          	auipc	a0,0x14
    80002fc6:	22e50513          	addi	a0,a0,558 # 800171f0 <tickslock>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	e48080e7          	jalr	-440(ra) # 80000e12 <release>
  return xticks;
}
    80002fd2:	02049513          	slli	a0,s1,0x20
    80002fd6:	9101                	srli	a0,a0,0x20
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	64a2                	ld	s1,8(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <sys_top>:

uint64
sys_top(void)
{
    80002fe2:	8c010113          	addi	sp,sp,-1856
    80002fe6:	72113c23          	sd	ra,1848(sp)
    80002fea:	72813823          	sd	s0,1840(sp)
    80002fee:	72913423          	sd	s1,1832(sp)
    80002ff2:	74010413          	addi	s0,sp,1856
    //printf("1");
    struct proc *p = myproc();
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	b3e080e7          	jalr	-1218(ra) # 80001b34 <myproc>
    80002ffe:	84aa                	mv	s1,a0
    struct top t;
    top(&t);
    80003000:	8d040513          	addi	a0,s0,-1840
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	73a080e7          	jalr	1850(ra) # 8000273e <top>

    uint64 a;
    argaddr(0, &a);
    8000300c:	8c840593          	addi	a1,s0,-1848
    80003010:	4501                	li	a0,0
    80003012:	00000097          	auipc	ra,0x0
    80003016:	d2c080e7          	jalr	-724(ra) # 80002d3e <argaddr>

    return copyout(p->pagetable, a, (char *) &t, sizeof(struct top));
    8000301a:	70c00693          	li	a3,1804
    8000301e:	8d040613          	addi	a2,s0,-1840
    80003022:	8c843583          	ld	a1,-1848(s0)
    80003026:	68a8                	ld	a0,80(s1)
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	7c8080e7          	jalr	1992(ra) # 800017f0 <copyout>

}
    80003030:	73813083          	ld	ra,1848(sp)
    80003034:	73013403          	ld	s0,1840(sp)
    80003038:	72813483          	ld	s1,1832(sp)
    8000303c:	74010113          	addi	sp,sp,1856
    80003040:	8082                	ret

0000000080003042 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003042:	7179                	addi	sp,sp,-48
    80003044:	f406                	sd	ra,40(sp)
    80003046:	f022                	sd	s0,32(sp)
    80003048:	ec26                	sd	s1,24(sp)
    8000304a:	e84a                	sd	s2,16(sp)
    8000304c:	e44e                	sd	s3,8(sp)
    8000304e:	e052                	sd	s4,0(sp)
    80003050:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003052:	00005597          	auipc	a1,0x5
    80003056:	4ee58593          	addi	a1,a1,1262 # 80008540 <syscalls+0xc0>
    8000305a:	00014517          	auipc	a0,0x14
    8000305e:	1ae50513          	addi	a0,a0,430 # 80017208 <bcache>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	c6c080e7          	jalr	-916(ra) # 80000cce <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000306a:	0001c797          	auipc	a5,0x1c
    8000306e:	19e78793          	addi	a5,a5,414 # 8001f208 <bcache+0x8000>
    80003072:	0001c717          	auipc	a4,0x1c
    80003076:	3fe70713          	addi	a4,a4,1022 # 8001f470 <bcache+0x8268>
    8000307a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000307e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003082:	00014497          	auipc	s1,0x14
    80003086:	19e48493          	addi	s1,s1,414 # 80017220 <bcache+0x18>
    b->next = bcache.head.next;
    8000308a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000308c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000308e:	00005a17          	auipc	s4,0x5
    80003092:	4baa0a13          	addi	s4,s4,1210 # 80008548 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003096:	2b893783          	ld	a5,696(s2)
    8000309a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000309c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030a0:	85d2                	mv	a1,s4
    800030a2:	01048513          	addi	a0,s1,16
    800030a6:	00001097          	auipc	ra,0x1
    800030aa:	4c4080e7          	jalr	1220(ra) # 8000456a <initsleeplock>
    bcache.head.next->prev = b;
    800030ae:	2b893783          	ld	a5,696(s2)
    800030b2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b8:	45848493          	addi	s1,s1,1112
    800030bc:	fd349de3          	bne	s1,s3,80003096 <binit+0x54>
  }
}
    800030c0:	70a2                	ld	ra,40(sp)
    800030c2:	7402                	ld	s0,32(sp)
    800030c4:	64e2                	ld	s1,24(sp)
    800030c6:	6942                	ld	s2,16(sp)
    800030c8:	69a2                	ld	s3,8(sp)
    800030ca:	6a02                	ld	s4,0(sp)
    800030cc:	6145                	addi	sp,sp,48
    800030ce:	8082                	ret

00000000800030d0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030d0:	7179                	addi	sp,sp,-48
    800030d2:	f406                	sd	ra,40(sp)
    800030d4:	f022                	sd	s0,32(sp)
    800030d6:	ec26                	sd	s1,24(sp)
    800030d8:	e84a                	sd	s2,16(sp)
    800030da:	e44e                	sd	s3,8(sp)
    800030dc:	1800                	addi	s0,sp,48
    800030de:	892a                	mv	s2,a0
    800030e0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030e2:	00014517          	auipc	a0,0x14
    800030e6:	12650513          	addi	a0,a0,294 # 80017208 <bcache>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	c74080e7          	jalr	-908(ra) # 80000d5e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030f2:	0001c497          	auipc	s1,0x1c
    800030f6:	3ce4b483          	ld	s1,974(s1) # 8001f4c0 <bcache+0x82b8>
    800030fa:	0001c797          	auipc	a5,0x1c
    800030fe:	37678793          	addi	a5,a5,886 # 8001f470 <bcache+0x8268>
    80003102:	02f48f63          	beq	s1,a5,80003140 <bread+0x70>
    80003106:	873e                	mv	a4,a5
    80003108:	a021                	j	80003110 <bread+0x40>
    8000310a:	68a4                	ld	s1,80(s1)
    8000310c:	02e48a63          	beq	s1,a4,80003140 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003110:	449c                	lw	a5,8(s1)
    80003112:	ff279ce3          	bne	a5,s2,8000310a <bread+0x3a>
    80003116:	44dc                	lw	a5,12(s1)
    80003118:	ff3799e3          	bne	a5,s3,8000310a <bread+0x3a>
      b->refcnt++;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	2785                	addiw	a5,a5,1
    80003120:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003122:	00014517          	auipc	a0,0x14
    80003126:	0e650513          	addi	a0,a0,230 # 80017208 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	ce8080e7          	jalr	-792(ra) # 80000e12 <release>
      acquiresleep(&b->lock);
    80003132:	01048513          	addi	a0,s1,16
    80003136:	00001097          	auipc	ra,0x1
    8000313a:	46e080e7          	jalr	1134(ra) # 800045a4 <acquiresleep>
      return b;
    8000313e:	a8b9                	j	8000319c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003140:	0001c497          	auipc	s1,0x1c
    80003144:	3784b483          	ld	s1,888(s1) # 8001f4b8 <bcache+0x82b0>
    80003148:	0001c797          	auipc	a5,0x1c
    8000314c:	32878793          	addi	a5,a5,808 # 8001f470 <bcache+0x8268>
    80003150:	00f48863          	beq	s1,a5,80003160 <bread+0x90>
    80003154:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003156:	40bc                	lw	a5,64(s1)
    80003158:	cf81                	beqz	a5,80003170 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000315a:	64a4                	ld	s1,72(s1)
    8000315c:	fee49de3          	bne	s1,a4,80003156 <bread+0x86>
  panic("bget: no buffers");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	3f050513          	addi	a0,a0,1008 # 80008550 <syscalls+0xd0>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	55e080e7          	jalr	1374(ra) # 800006c6 <panic>
      b->dev = dev;
    80003170:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003174:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003178:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000317c:	4785                	li	a5,1
    8000317e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003180:	00014517          	auipc	a0,0x14
    80003184:	08850513          	addi	a0,a0,136 # 80017208 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	c8a080e7          	jalr	-886(ra) # 80000e12 <release>
      acquiresleep(&b->lock);
    80003190:	01048513          	addi	a0,s1,16
    80003194:	00001097          	auipc	ra,0x1
    80003198:	410080e7          	jalr	1040(ra) # 800045a4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000319c:	409c                	lw	a5,0(s1)
    8000319e:	cb89                	beqz	a5,800031b0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031a0:	8526                	mv	a0,s1
    800031a2:	70a2                	ld	ra,40(sp)
    800031a4:	7402                	ld	s0,32(sp)
    800031a6:	64e2                	ld	s1,24(sp)
    800031a8:	6942                	ld	s2,16(sp)
    800031aa:	69a2                	ld	s3,8(sp)
    800031ac:	6145                	addi	sp,sp,48
    800031ae:	8082                	ret
    virtio_disk_rw(b, 0);
    800031b0:	4581                	li	a1,0
    800031b2:	8526                	mv	a0,s1
    800031b4:	00003097          	auipc	ra,0x3
    800031b8:	fd0080e7          	jalr	-48(ra) # 80006184 <virtio_disk_rw>
    b->valid = 1;
    800031bc:	4785                	li	a5,1
    800031be:	c09c                	sw	a5,0(s1)
  return b;
    800031c0:	b7c5                	j	800031a0 <bread+0xd0>

00000000800031c2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031c2:	1101                	addi	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	e426                	sd	s1,8(sp)
    800031ca:	1000                	addi	s0,sp,32
    800031cc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ce:	0541                	addi	a0,a0,16
    800031d0:	00001097          	auipc	ra,0x1
    800031d4:	46e080e7          	jalr	1134(ra) # 8000463e <holdingsleep>
    800031d8:	cd01                	beqz	a0,800031f0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031da:	4585                	li	a1,1
    800031dc:	8526                	mv	a0,s1
    800031de:	00003097          	auipc	ra,0x3
    800031e2:	fa6080e7          	jalr	-90(ra) # 80006184 <virtio_disk_rw>
}
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	64a2                	ld	s1,8(sp)
    800031ec:	6105                	addi	sp,sp,32
    800031ee:	8082                	ret
    panic("bwrite");
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	37850513          	addi	a0,a0,888 # 80008568 <syscalls+0xe8>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	4ce080e7          	jalr	1230(ra) # 800006c6 <panic>

0000000080003200 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003200:	1101                	addi	sp,sp,-32
    80003202:	ec06                	sd	ra,24(sp)
    80003204:	e822                	sd	s0,16(sp)
    80003206:	e426                	sd	s1,8(sp)
    80003208:	e04a                	sd	s2,0(sp)
    8000320a:	1000                	addi	s0,sp,32
    8000320c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000320e:	01050913          	addi	s2,a0,16
    80003212:	854a                	mv	a0,s2
    80003214:	00001097          	auipc	ra,0x1
    80003218:	42a080e7          	jalr	1066(ra) # 8000463e <holdingsleep>
    8000321c:	c92d                	beqz	a0,8000328e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000321e:	854a                	mv	a0,s2
    80003220:	00001097          	auipc	ra,0x1
    80003224:	3da080e7          	jalr	986(ra) # 800045fa <releasesleep>

  acquire(&bcache.lock);
    80003228:	00014517          	auipc	a0,0x14
    8000322c:	fe050513          	addi	a0,a0,-32 # 80017208 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	b2e080e7          	jalr	-1234(ra) # 80000d5e <acquire>
  b->refcnt--;
    80003238:	40bc                	lw	a5,64(s1)
    8000323a:	37fd                	addiw	a5,a5,-1
    8000323c:	0007871b          	sext.w	a4,a5
    80003240:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003242:	eb05                	bnez	a4,80003272 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003244:	68bc                	ld	a5,80(s1)
    80003246:	64b8                	ld	a4,72(s1)
    80003248:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000324a:	64bc                	ld	a5,72(s1)
    8000324c:	68b8                	ld	a4,80(s1)
    8000324e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003250:	0001c797          	auipc	a5,0x1c
    80003254:	fb878793          	addi	a5,a5,-72 # 8001f208 <bcache+0x8000>
    80003258:	2b87b703          	ld	a4,696(a5)
    8000325c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000325e:	0001c717          	auipc	a4,0x1c
    80003262:	21270713          	addi	a4,a4,530 # 8001f470 <bcache+0x8268>
    80003266:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003268:	2b87b703          	ld	a4,696(a5)
    8000326c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000326e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003272:	00014517          	auipc	a0,0x14
    80003276:	f9650513          	addi	a0,a0,-106 # 80017208 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	b98080e7          	jalr	-1128(ra) # 80000e12 <release>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	64a2                	ld	s1,8(sp)
    80003288:	6902                	ld	s2,0(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret
    panic("brelse");
    8000328e:	00005517          	auipc	a0,0x5
    80003292:	2e250513          	addi	a0,a0,738 # 80008570 <syscalls+0xf0>
    80003296:	ffffd097          	auipc	ra,0xffffd
    8000329a:	430080e7          	jalr	1072(ra) # 800006c6 <panic>

000000008000329e <bpin>:

void
bpin(struct buf *b) {
    8000329e:	1101                	addi	sp,sp,-32
    800032a0:	ec06                	sd	ra,24(sp)
    800032a2:	e822                	sd	s0,16(sp)
    800032a4:	e426                	sd	s1,8(sp)
    800032a6:	1000                	addi	s0,sp,32
    800032a8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032aa:	00014517          	auipc	a0,0x14
    800032ae:	f5e50513          	addi	a0,a0,-162 # 80017208 <bcache>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	aac080e7          	jalr	-1364(ra) # 80000d5e <acquire>
  b->refcnt++;
    800032ba:	40bc                	lw	a5,64(s1)
    800032bc:	2785                	addiw	a5,a5,1
    800032be:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032c0:	00014517          	auipc	a0,0x14
    800032c4:	f4850513          	addi	a0,a0,-184 # 80017208 <bcache>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	b4a080e7          	jalr	-1206(ra) # 80000e12 <release>
}
    800032d0:	60e2                	ld	ra,24(sp)
    800032d2:	6442                	ld	s0,16(sp)
    800032d4:	64a2                	ld	s1,8(sp)
    800032d6:	6105                	addi	sp,sp,32
    800032d8:	8082                	ret

00000000800032da <bunpin>:

void
bunpin(struct buf *b) {
    800032da:	1101                	addi	sp,sp,-32
    800032dc:	ec06                	sd	ra,24(sp)
    800032de:	e822                	sd	s0,16(sp)
    800032e0:	e426                	sd	s1,8(sp)
    800032e2:	1000                	addi	s0,sp,32
    800032e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e6:	00014517          	auipc	a0,0x14
    800032ea:	f2250513          	addi	a0,a0,-222 # 80017208 <bcache>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	a70080e7          	jalr	-1424(ra) # 80000d5e <acquire>
  b->refcnt--;
    800032f6:	40bc                	lw	a5,64(s1)
    800032f8:	37fd                	addiw	a5,a5,-1
    800032fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032fc:	00014517          	auipc	a0,0x14
    80003300:	f0c50513          	addi	a0,a0,-244 # 80017208 <bcache>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	b0e080e7          	jalr	-1266(ra) # 80000e12 <release>
}
    8000330c:	60e2                	ld	ra,24(sp)
    8000330e:	6442                	ld	s0,16(sp)
    80003310:	64a2                	ld	s1,8(sp)
    80003312:	6105                	addi	sp,sp,32
    80003314:	8082                	ret

0000000080003316 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003316:	1101                	addi	sp,sp,-32
    80003318:	ec06                	sd	ra,24(sp)
    8000331a:	e822                	sd	s0,16(sp)
    8000331c:	e426                	sd	s1,8(sp)
    8000331e:	e04a                	sd	s2,0(sp)
    80003320:	1000                	addi	s0,sp,32
    80003322:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003324:	00d5d59b          	srliw	a1,a1,0xd
    80003328:	0001c797          	auipc	a5,0x1c
    8000332c:	5bc7a783          	lw	a5,1468(a5) # 8001f8e4 <sb+0x1c>
    80003330:	9dbd                	addw	a1,a1,a5
    80003332:	00000097          	auipc	ra,0x0
    80003336:	d9e080e7          	jalr	-610(ra) # 800030d0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000333a:	0074f713          	andi	a4,s1,7
    8000333e:	4785                	li	a5,1
    80003340:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003344:	14ce                	slli	s1,s1,0x33
    80003346:	90d9                	srli	s1,s1,0x36
    80003348:	00950733          	add	a4,a0,s1
    8000334c:	05874703          	lbu	a4,88(a4)
    80003350:	00e7f6b3          	and	a3,a5,a4
    80003354:	c69d                	beqz	a3,80003382 <bfree+0x6c>
    80003356:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003358:	94aa                	add	s1,s1,a0
    8000335a:	fff7c793          	not	a5,a5
    8000335e:	8ff9                	and	a5,a5,a4
    80003360:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003364:	00001097          	auipc	ra,0x1
    80003368:	120080e7          	jalr	288(ra) # 80004484 <log_write>
  brelse(bp);
    8000336c:	854a                	mv	a0,s2
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	e92080e7          	jalr	-366(ra) # 80003200 <brelse>
}
    80003376:	60e2                	ld	ra,24(sp)
    80003378:	6442                	ld	s0,16(sp)
    8000337a:	64a2                	ld	s1,8(sp)
    8000337c:	6902                	ld	s2,0(sp)
    8000337e:	6105                	addi	sp,sp,32
    80003380:	8082                	ret
    panic("freeing free block");
    80003382:	00005517          	auipc	a0,0x5
    80003386:	1f650513          	addi	a0,a0,502 # 80008578 <syscalls+0xf8>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	33c080e7          	jalr	828(ra) # 800006c6 <panic>

0000000080003392 <balloc>:
{
    80003392:	711d                	addi	sp,sp,-96
    80003394:	ec86                	sd	ra,88(sp)
    80003396:	e8a2                	sd	s0,80(sp)
    80003398:	e4a6                	sd	s1,72(sp)
    8000339a:	e0ca                	sd	s2,64(sp)
    8000339c:	fc4e                	sd	s3,56(sp)
    8000339e:	f852                	sd	s4,48(sp)
    800033a0:	f456                	sd	s5,40(sp)
    800033a2:	f05a                	sd	s6,32(sp)
    800033a4:	ec5e                	sd	s7,24(sp)
    800033a6:	e862                	sd	s8,16(sp)
    800033a8:	e466                	sd	s9,8(sp)
    800033aa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033ac:	0001c797          	auipc	a5,0x1c
    800033b0:	5207a783          	lw	a5,1312(a5) # 8001f8cc <sb+0x4>
    800033b4:	10078163          	beqz	a5,800034b6 <balloc+0x124>
    800033b8:	8baa                	mv	s7,a0
    800033ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033bc:	0001cb17          	auipc	s6,0x1c
    800033c0:	50cb0b13          	addi	s6,s6,1292 # 8001f8c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033ca:	6c89                	lui	s9,0x2
    800033cc:	a061                	j	80003454 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ce:	974a                	add	a4,a4,s2
    800033d0:	8fd5                	or	a5,a5,a3
    800033d2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033d6:	854a                	mv	a0,s2
    800033d8:	00001097          	auipc	ra,0x1
    800033dc:	0ac080e7          	jalr	172(ra) # 80004484 <log_write>
        brelse(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	e1e080e7          	jalr	-482(ra) # 80003200 <brelse>
  bp = bread(dev, bno);
    800033ea:	85a6                	mv	a1,s1
    800033ec:	855e                	mv	a0,s7
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	ce2080e7          	jalr	-798(ra) # 800030d0 <bread>
    800033f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033f8:	40000613          	li	a2,1024
    800033fc:	4581                	li	a1,0
    800033fe:	05850513          	addi	a0,a0,88
    80003402:	ffffe097          	auipc	ra,0xffffe
    80003406:	a58080e7          	jalr	-1448(ra) # 80000e5a <memset>
  log_write(bp);
    8000340a:	854a                	mv	a0,s2
    8000340c:	00001097          	auipc	ra,0x1
    80003410:	078080e7          	jalr	120(ra) # 80004484 <log_write>
  brelse(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	dea080e7          	jalr	-534(ra) # 80003200 <brelse>
}
    8000341e:	8526                	mv	a0,s1
    80003420:	60e6                	ld	ra,88(sp)
    80003422:	6446                	ld	s0,80(sp)
    80003424:	64a6                	ld	s1,72(sp)
    80003426:	6906                	ld	s2,64(sp)
    80003428:	79e2                	ld	s3,56(sp)
    8000342a:	7a42                	ld	s4,48(sp)
    8000342c:	7aa2                	ld	s5,40(sp)
    8000342e:	7b02                	ld	s6,32(sp)
    80003430:	6be2                	ld	s7,24(sp)
    80003432:	6c42                	ld	s8,16(sp)
    80003434:	6ca2                	ld	s9,8(sp)
    80003436:	6125                	addi	sp,sp,96
    80003438:	8082                	ret
    brelse(bp);
    8000343a:	854a                	mv	a0,s2
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	dc4080e7          	jalr	-572(ra) # 80003200 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003444:	015c87bb          	addw	a5,s9,s5
    80003448:	00078a9b          	sext.w	s5,a5
    8000344c:	004b2703          	lw	a4,4(s6)
    80003450:	06eaf363          	bgeu	s5,a4,800034b6 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003454:	41fad79b          	sraiw	a5,s5,0x1f
    80003458:	0137d79b          	srliw	a5,a5,0x13
    8000345c:	015787bb          	addw	a5,a5,s5
    80003460:	40d7d79b          	sraiw	a5,a5,0xd
    80003464:	01cb2583          	lw	a1,28(s6)
    80003468:	9dbd                	addw	a1,a1,a5
    8000346a:	855e                	mv	a0,s7
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	c64080e7          	jalr	-924(ra) # 800030d0 <bread>
    80003474:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003476:	004b2503          	lw	a0,4(s6)
    8000347a:	000a849b          	sext.w	s1,s5
    8000347e:	8662                	mv	a2,s8
    80003480:	faa4fde3          	bgeu	s1,a0,8000343a <balloc+0xa8>
      m = 1 << (bi % 8);
    80003484:	41f6579b          	sraiw	a5,a2,0x1f
    80003488:	01d7d69b          	srliw	a3,a5,0x1d
    8000348c:	00c6873b          	addw	a4,a3,a2
    80003490:	00777793          	andi	a5,a4,7
    80003494:	9f95                	subw	a5,a5,a3
    80003496:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000349a:	4037571b          	sraiw	a4,a4,0x3
    8000349e:	00e906b3          	add	a3,s2,a4
    800034a2:	0586c683          	lbu	a3,88(a3)
    800034a6:	00d7f5b3          	and	a1,a5,a3
    800034aa:	d195                	beqz	a1,800033ce <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ac:	2605                	addiw	a2,a2,1
    800034ae:	2485                	addiw	s1,s1,1
    800034b0:	fd4618e3          	bne	a2,s4,80003480 <balloc+0xee>
    800034b4:	b759                	j	8000343a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034b6:	00005517          	auipc	a0,0x5
    800034ba:	0da50513          	addi	a0,a0,218 # 80008590 <syscalls+0x110>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	252080e7          	jalr	594(ra) # 80000710 <printf>
  return 0;
    800034c6:	4481                	li	s1,0
    800034c8:	bf99                	j	8000341e <balloc+0x8c>

00000000800034ca <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ca:	7179                	addi	sp,sp,-48
    800034cc:	f406                	sd	ra,40(sp)
    800034ce:	f022                	sd	s0,32(sp)
    800034d0:	ec26                	sd	s1,24(sp)
    800034d2:	e84a                	sd	s2,16(sp)
    800034d4:	e44e                	sd	s3,8(sp)
    800034d6:	e052                	sd	s4,0(sp)
    800034d8:	1800                	addi	s0,sp,48
    800034da:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034dc:	47ad                	li	a5,11
    800034de:	02b7e763          	bltu	a5,a1,8000350c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800034e2:	02059493          	slli	s1,a1,0x20
    800034e6:	9081                	srli	s1,s1,0x20
    800034e8:	048a                	slli	s1,s1,0x2
    800034ea:	94aa                	add	s1,s1,a0
    800034ec:	0504a903          	lw	s2,80(s1)
    800034f0:	06091e63          	bnez	s2,8000356c <bmap+0xa2>
      addr = balloc(ip->dev);
    800034f4:	4108                	lw	a0,0(a0)
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	e9c080e7          	jalr	-356(ra) # 80003392 <balloc>
    800034fe:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003502:	06090563          	beqz	s2,8000356c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003506:	0524a823          	sw	s2,80(s1)
    8000350a:	a08d                	j	8000356c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000350c:	ff45849b          	addiw	s1,a1,-12
    80003510:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003514:	0ff00793          	li	a5,255
    80003518:	08e7e563          	bltu	a5,a4,800035a2 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000351c:	08052903          	lw	s2,128(a0)
    80003520:	00091d63          	bnez	s2,8000353a <bmap+0x70>
      addr = balloc(ip->dev);
    80003524:	4108                	lw	a0,0(a0)
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	e6c080e7          	jalr	-404(ra) # 80003392 <balloc>
    8000352e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003532:	02090d63          	beqz	s2,8000356c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003536:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000353a:	85ca                	mv	a1,s2
    8000353c:	0009a503          	lw	a0,0(s3)
    80003540:	00000097          	auipc	ra,0x0
    80003544:	b90080e7          	jalr	-1136(ra) # 800030d0 <bread>
    80003548:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000354a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000354e:	02049593          	slli	a1,s1,0x20
    80003552:	9181                	srli	a1,a1,0x20
    80003554:	058a                	slli	a1,a1,0x2
    80003556:	00b784b3          	add	s1,a5,a1
    8000355a:	0004a903          	lw	s2,0(s1)
    8000355e:	02090063          	beqz	s2,8000357e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003562:	8552                	mv	a0,s4
    80003564:	00000097          	auipc	ra,0x0
    80003568:	c9c080e7          	jalr	-868(ra) # 80003200 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000356c:	854a                	mv	a0,s2
    8000356e:	70a2                	ld	ra,40(sp)
    80003570:	7402                	ld	s0,32(sp)
    80003572:	64e2                	ld	s1,24(sp)
    80003574:	6942                	ld	s2,16(sp)
    80003576:	69a2                	ld	s3,8(sp)
    80003578:	6a02                	ld	s4,0(sp)
    8000357a:	6145                	addi	sp,sp,48
    8000357c:	8082                	ret
      addr = balloc(ip->dev);
    8000357e:	0009a503          	lw	a0,0(s3)
    80003582:	00000097          	auipc	ra,0x0
    80003586:	e10080e7          	jalr	-496(ra) # 80003392 <balloc>
    8000358a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000358e:	fc090ae3          	beqz	s2,80003562 <bmap+0x98>
        a[bn] = addr;
    80003592:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003596:	8552                	mv	a0,s4
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	eec080e7          	jalr	-276(ra) # 80004484 <log_write>
    800035a0:	b7c9                	j	80003562 <bmap+0x98>
  panic("bmap: out of range");
    800035a2:	00005517          	auipc	a0,0x5
    800035a6:	00650513          	addi	a0,a0,6 # 800085a8 <syscalls+0x128>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	11c080e7          	jalr	284(ra) # 800006c6 <panic>

00000000800035b2 <iget>:
{
    800035b2:	7179                	addi	sp,sp,-48
    800035b4:	f406                	sd	ra,40(sp)
    800035b6:	f022                	sd	s0,32(sp)
    800035b8:	ec26                	sd	s1,24(sp)
    800035ba:	e84a                	sd	s2,16(sp)
    800035bc:	e44e                	sd	s3,8(sp)
    800035be:	e052                	sd	s4,0(sp)
    800035c0:	1800                	addi	s0,sp,48
    800035c2:	89aa                	mv	s3,a0
    800035c4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035c6:	0001c517          	auipc	a0,0x1c
    800035ca:	32250513          	addi	a0,a0,802 # 8001f8e8 <itable>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	790080e7          	jalr	1936(ra) # 80000d5e <acquire>
  empty = 0;
    800035d6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d8:	0001c497          	auipc	s1,0x1c
    800035dc:	32848493          	addi	s1,s1,808 # 8001f900 <itable+0x18>
    800035e0:	0001e697          	auipc	a3,0x1e
    800035e4:	db068693          	addi	a3,a3,-592 # 80021390 <log>
    800035e8:	a039                	j	800035f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ea:	02090b63          	beqz	s2,80003620 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ee:	08848493          	addi	s1,s1,136
    800035f2:	02d48a63          	beq	s1,a3,80003626 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035f6:	449c                	lw	a5,8(s1)
    800035f8:	fef059e3          	blez	a5,800035ea <iget+0x38>
    800035fc:	4098                	lw	a4,0(s1)
    800035fe:	ff3716e3          	bne	a4,s3,800035ea <iget+0x38>
    80003602:	40d8                	lw	a4,4(s1)
    80003604:	ff4713e3          	bne	a4,s4,800035ea <iget+0x38>
      ip->ref++;
    80003608:	2785                	addiw	a5,a5,1
    8000360a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000360c:	0001c517          	auipc	a0,0x1c
    80003610:	2dc50513          	addi	a0,a0,732 # 8001f8e8 <itable>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	7fe080e7          	jalr	2046(ra) # 80000e12 <release>
      return ip;
    8000361c:	8926                	mv	s2,s1
    8000361e:	a03d                	j	8000364c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003620:	f7f9                	bnez	a5,800035ee <iget+0x3c>
    80003622:	8926                	mv	s2,s1
    80003624:	b7e9                	j	800035ee <iget+0x3c>
  if(empty == 0)
    80003626:	02090c63          	beqz	s2,8000365e <iget+0xac>
  ip->dev = dev;
    8000362a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000362e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003632:	4785                	li	a5,1
    80003634:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003638:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000363c:	0001c517          	auipc	a0,0x1c
    80003640:	2ac50513          	addi	a0,a0,684 # 8001f8e8 <itable>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	7ce080e7          	jalr	1998(ra) # 80000e12 <release>
}
    8000364c:	854a                	mv	a0,s2
    8000364e:	70a2                	ld	ra,40(sp)
    80003650:	7402                	ld	s0,32(sp)
    80003652:	64e2                	ld	s1,24(sp)
    80003654:	6942                	ld	s2,16(sp)
    80003656:	69a2                	ld	s3,8(sp)
    80003658:	6a02                	ld	s4,0(sp)
    8000365a:	6145                	addi	sp,sp,48
    8000365c:	8082                	ret
    panic("iget: no inodes");
    8000365e:	00005517          	auipc	a0,0x5
    80003662:	f6250513          	addi	a0,a0,-158 # 800085c0 <syscalls+0x140>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	060080e7          	jalr	96(ra) # 800006c6 <panic>

000000008000366e <fsinit>:
fsinit(int dev) {
    8000366e:	7179                	addi	sp,sp,-48
    80003670:	f406                	sd	ra,40(sp)
    80003672:	f022                	sd	s0,32(sp)
    80003674:	ec26                	sd	s1,24(sp)
    80003676:	e84a                	sd	s2,16(sp)
    80003678:	e44e                	sd	s3,8(sp)
    8000367a:	1800                	addi	s0,sp,48
    8000367c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000367e:	4585                	li	a1,1
    80003680:	00000097          	auipc	ra,0x0
    80003684:	a50080e7          	jalr	-1456(ra) # 800030d0 <bread>
    80003688:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000368a:	0001c997          	auipc	s3,0x1c
    8000368e:	23e98993          	addi	s3,s3,574 # 8001f8c8 <sb>
    80003692:	02000613          	li	a2,32
    80003696:	05850593          	addi	a1,a0,88
    8000369a:	854e                	mv	a0,s3
    8000369c:	ffffe097          	auipc	ra,0xffffe
    800036a0:	81a080e7          	jalr	-2022(ra) # 80000eb6 <memmove>
  brelse(bp);
    800036a4:	8526                	mv	a0,s1
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	b5a080e7          	jalr	-1190(ra) # 80003200 <brelse>
  if(sb.magic != FSMAGIC)
    800036ae:	0009a703          	lw	a4,0(s3)
    800036b2:	102037b7          	lui	a5,0x10203
    800036b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036ba:	02f71263          	bne	a4,a5,800036de <fsinit+0x70>
  initlog(dev, &sb);
    800036be:	0001c597          	auipc	a1,0x1c
    800036c2:	20a58593          	addi	a1,a1,522 # 8001f8c8 <sb>
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	b40080e7          	jalr	-1216(ra) # 80004208 <initlog>
}
    800036d0:	70a2                	ld	ra,40(sp)
    800036d2:	7402                	ld	s0,32(sp)
    800036d4:	64e2                	ld	s1,24(sp)
    800036d6:	6942                	ld	s2,16(sp)
    800036d8:	69a2                	ld	s3,8(sp)
    800036da:	6145                	addi	sp,sp,48
    800036dc:	8082                	ret
    panic("invalid file system");
    800036de:	00005517          	auipc	a0,0x5
    800036e2:	ef250513          	addi	a0,a0,-270 # 800085d0 <syscalls+0x150>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	fe0080e7          	jalr	-32(ra) # 800006c6 <panic>

00000000800036ee <iinit>:
{
    800036ee:	7179                	addi	sp,sp,-48
    800036f0:	f406                	sd	ra,40(sp)
    800036f2:	f022                	sd	s0,32(sp)
    800036f4:	ec26                	sd	s1,24(sp)
    800036f6:	e84a                	sd	s2,16(sp)
    800036f8:	e44e                	sd	s3,8(sp)
    800036fa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036fc:	00005597          	auipc	a1,0x5
    80003700:	eec58593          	addi	a1,a1,-276 # 800085e8 <syscalls+0x168>
    80003704:	0001c517          	auipc	a0,0x1c
    80003708:	1e450513          	addi	a0,a0,484 # 8001f8e8 <itable>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	5c2080e7          	jalr	1474(ra) # 80000cce <initlock>
  for(i = 0; i < NINODE; i++) {
    80003714:	0001c497          	auipc	s1,0x1c
    80003718:	1fc48493          	addi	s1,s1,508 # 8001f910 <itable+0x28>
    8000371c:	0001e997          	auipc	s3,0x1e
    80003720:	c8498993          	addi	s3,s3,-892 # 800213a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003724:	00005917          	auipc	s2,0x5
    80003728:	ecc90913          	addi	s2,s2,-308 # 800085f0 <syscalls+0x170>
    8000372c:	85ca                	mv	a1,s2
    8000372e:	8526                	mv	a0,s1
    80003730:	00001097          	auipc	ra,0x1
    80003734:	e3a080e7          	jalr	-454(ra) # 8000456a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003738:	08848493          	addi	s1,s1,136
    8000373c:	ff3498e3          	bne	s1,s3,8000372c <iinit+0x3e>
}
    80003740:	70a2                	ld	ra,40(sp)
    80003742:	7402                	ld	s0,32(sp)
    80003744:	64e2                	ld	s1,24(sp)
    80003746:	6942                	ld	s2,16(sp)
    80003748:	69a2                	ld	s3,8(sp)
    8000374a:	6145                	addi	sp,sp,48
    8000374c:	8082                	ret

000000008000374e <ialloc>:
{
    8000374e:	715d                	addi	sp,sp,-80
    80003750:	e486                	sd	ra,72(sp)
    80003752:	e0a2                	sd	s0,64(sp)
    80003754:	fc26                	sd	s1,56(sp)
    80003756:	f84a                	sd	s2,48(sp)
    80003758:	f44e                	sd	s3,40(sp)
    8000375a:	f052                	sd	s4,32(sp)
    8000375c:	ec56                	sd	s5,24(sp)
    8000375e:	e85a                	sd	s6,16(sp)
    80003760:	e45e                	sd	s7,8(sp)
    80003762:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003764:	0001c717          	auipc	a4,0x1c
    80003768:	17072703          	lw	a4,368(a4) # 8001f8d4 <sb+0xc>
    8000376c:	4785                	li	a5,1
    8000376e:	04e7fa63          	bgeu	a5,a4,800037c2 <ialloc+0x74>
    80003772:	8aaa                	mv	s5,a0
    80003774:	8bae                	mv	s7,a1
    80003776:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003778:	0001ca17          	auipc	s4,0x1c
    8000377c:	150a0a13          	addi	s4,s4,336 # 8001f8c8 <sb>
    80003780:	00048b1b          	sext.w	s6,s1
    80003784:	0044d793          	srli	a5,s1,0x4
    80003788:	018a2583          	lw	a1,24(s4)
    8000378c:	9dbd                	addw	a1,a1,a5
    8000378e:	8556                	mv	a0,s5
    80003790:	00000097          	auipc	ra,0x0
    80003794:	940080e7          	jalr	-1728(ra) # 800030d0 <bread>
    80003798:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000379a:	05850993          	addi	s3,a0,88
    8000379e:	00f4f793          	andi	a5,s1,15
    800037a2:	079a                	slli	a5,a5,0x6
    800037a4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037a6:	00099783          	lh	a5,0(s3)
    800037aa:	c3a1                	beqz	a5,800037ea <ialloc+0x9c>
    brelse(bp);
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	a54080e7          	jalr	-1452(ra) # 80003200 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b4:	0485                	addi	s1,s1,1
    800037b6:	00ca2703          	lw	a4,12(s4)
    800037ba:	0004879b          	sext.w	a5,s1
    800037be:	fce7e1e3          	bltu	a5,a4,80003780 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	e3650513          	addi	a0,a0,-458 # 800085f8 <syscalls+0x178>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	f46080e7          	jalr	-186(ra) # 80000710 <printf>
  return 0;
    800037d2:	4501                	li	a0,0
}
    800037d4:	60a6                	ld	ra,72(sp)
    800037d6:	6406                	ld	s0,64(sp)
    800037d8:	74e2                	ld	s1,56(sp)
    800037da:	7942                	ld	s2,48(sp)
    800037dc:	79a2                	ld	s3,40(sp)
    800037de:	7a02                	ld	s4,32(sp)
    800037e0:	6ae2                	ld	s5,24(sp)
    800037e2:	6b42                	ld	s6,16(sp)
    800037e4:	6ba2                	ld	s7,8(sp)
    800037e6:	6161                	addi	sp,sp,80
    800037e8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037ea:	04000613          	li	a2,64
    800037ee:	4581                	li	a1,0
    800037f0:	854e                	mv	a0,s3
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	668080e7          	jalr	1640(ra) # 80000e5a <memset>
      dip->type = type;
    800037fa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037fe:	854a                	mv	a0,s2
    80003800:	00001097          	auipc	ra,0x1
    80003804:	c84080e7          	jalr	-892(ra) # 80004484 <log_write>
      brelse(bp);
    80003808:	854a                	mv	a0,s2
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	9f6080e7          	jalr	-1546(ra) # 80003200 <brelse>
      return iget(dev, inum);
    80003812:	85da                	mv	a1,s6
    80003814:	8556                	mv	a0,s5
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	d9c080e7          	jalr	-612(ra) # 800035b2 <iget>
    8000381e:	bf5d                	j	800037d4 <ialloc+0x86>

0000000080003820 <iupdate>:
{
    80003820:	1101                	addi	sp,sp,-32
    80003822:	ec06                	sd	ra,24(sp)
    80003824:	e822                	sd	s0,16(sp)
    80003826:	e426                	sd	s1,8(sp)
    80003828:	e04a                	sd	s2,0(sp)
    8000382a:	1000                	addi	s0,sp,32
    8000382c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000382e:	415c                	lw	a5,4(a0)
    80003830:	0047d79b          	srliw	a5,a5,0x4
    80003834:	0001c597          	auipc	a1,0x1c
    80003838:	0ac5a583          	lw	a1,172(a1) # 8001f8e0 <sb+0x18>
    8000383c:	9dbd                	addw	a1,a1,a5
    8000383e:	4108                	lw	a0,0(a0)
    80003840:	00000097          	auipc	ra,0x0
    80003844:	890080e7          	jalr	-1904(ra) # 800030d0 <bread>
    80003848:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000384a:	05850793          	addi	a5,a0,88
    8000384e:	40c8                	lw	a0,4(s1)
    80003850:	893d                	andi	a0,a0,15
    80003852:	051a                	slli	a0,a0,0x6
    80003854:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003856:	04449703          	lh	a4,68(s1)
    8000385a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000385e:	04649703          	lh	a4,70(s1)
    80003862:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003866:	04849703          	lh	a4,72(s1)
    8000386a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000386e:	04a49703          	lh	a4,74(s1)
    80003872:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003876:	44f8                	lw	a4,76(s1)
    80003878:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000387a:	03400613          	li	a2,52
    8000387e:	05048593          	addi	a1,s1,80
    80003882:	0531                	addi	a0,a0,12
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	632080e7          	jalr	1586(ra) # 80000eb6 <memmove>
  log_write(bp);
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	bf6080e7          	jalr	-1034(ra) # 80004484 <log_write>
  brelse(bp);
    80003896:	854a                	mv	a0,s2
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	968080e7          	jalr	-1688(ra) # 80003200 <brelse>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6902                	ld	s2,0(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret

00000000800038ac <idup>:
{
    800038ac:	1101                	addi	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	1000                	addi	s0,sp,32
    800038b6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038b8:	0001c517          	auipc	a0,0x1c
    800038bc:	03050513          	addi	a0,a0,48 # 8001f8e8 <itable>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	49e080e7          	jalr	1182(ra) # 80000d5e <acquire>
  ip->ref++;
    800038c8:	449c                	lw	a5,8(s1)
    800038ca:	2785                	addiw	a5,a5,1
    800038cc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038ce:	0001c517          	auipc	a0,0x1c
    800038d2:	01a50513          	addi	a0,a0,26 # 8001f8e8 <itable>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	53c080e7          	jalr	1340(ra) # 80000e12 <release>
}
    800038de:	8526                	mv	a0,s1
    800038e0:	60e2                	ld	ra,24(sp)
    800038e2:	6442                	ld	s0,16(sp)
    800038e4:	64a2                	ld	s1,8(sp)
    800038e6:	6105                	addi	sp,sp,32
    800038e8:	8082                	ret

00000000800038ea <ilock>:
{
    800038ea:	1101                	addi	sp,sp,-32
    800038ec:	ec06                	sd	ra,24(sp)
    800038ee:	e822                	sd	s0,16(sp)
    800038f0:	e426                	sd	s1,8(sp)
    800038f2:	e04a                	sd	s2,0(sp)
    800038f4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038f6:	c115                	beqz	a0,8000391a <ilock+0x30>
    800038f8:	84aa                	mv	s1,a0
    800038fa:	451c                	lw	a5,8(a0)
    800038fc:	00f05f63          	blez	a5,8000391a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003900:	0541                	addi	a0,a0,16
    80003902:	00001097          	auipc	ra,0x1
    80003906:	ca2080e7          	jalr	-862(ra) # 800045a4 <acquiresleep>
  if(ip->valid == 0){
    8000390a:	40bc                	lw	a5,64(s1)
    8000390c:	cf99                	beqz	a5,8000392a <ilock+0x40>
}
    8000390e:	60e2                	ld	ra,24(sp)
    80003910:	6442                	ld	s0,16(sp)
    80003912:	64a2                	ld	s1,8(sp)
    80003914:	6902                	ld	s2,0(sp)
    80003916:	6105                	addi	sp,sp,32
    80003918:	8082                	ret
    panic("ilock");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	cf650513          	addi	a0,a0,-778 # 80008610 <syscalls+0x190>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	da4080e7          	jalr	-604(ra) # 800006c6 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000392a:	40dc                	lw	a5,4(s1)
    8000392c:	0047d79b          	srliw	a5,a5,0x4
    80003930:	0001c597          	auipc	a1,0x1c
    80003934:	fb05a583          	lw	a1,-80(a1) # 8001f8e0 <sb+0x18>
    80003938:	9dbd                	addw	a1,a1,a5
    8000393a:	4088                	lw	a0,0(s1)
    8000393c:	fffff097          	auipc	ra,0xfffff
    80003940:	794080e7          	jalr	1940(ra) # 800030d0 <bread>
    80003944:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003946:	05850593          	addi	a1,a0,88
    8000394a:	40dc                	lw	a5,4(s1)
    8000394c:	8bbd                	andi	a5,a5,15
    8000394e:	079a                	slli	a5,a5,0x6
    80003950:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003952:	00059783          	lh	a5,0(a1)
    80003956:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000395a:	00259783          	lh	a5,2(a1)
    8000395e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003962:	00459783          	lh	a5,4(a1)
    80003966:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000396a:	00659783          	lh	a5,6(a1)
    8000396e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003972:	459c                	lw	a5,8(a1)
    80003974:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003976:	03400613          	li	a2,52
    8000397a:	05b1                	addi	a1,a1,12
    8000397c:	05048513          	addi	a0,s1,80
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	536080e7          	jalr	1334(ra) # 80000eb6 <memmove>
    brelse(bp);
    80003988:	854a                	mv	a0,s2
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	876080e7          	jalr	-1930(ra) # 80003200 <brelse>
    ip->valid = 1;
    80003992:	4785                	li	a5,1
    80003994:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003996:	04449783          	lh	a5,68(s1)
    8000399a:	fbb5                	bnez	a5,8000390e <ilock+0x24>
      panic("ilock: no type");
    8000399c:	00005517          	auipc	a0,0x5
    800039a0:	c7c50513          	addi	a0,a0,-900 # 80008618 <syscalls+0x198>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	d22080e7          	jalr	-734(ra) # 800006c6 <panic>

00000000800039ac <iunlock>:
{
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	e04a                	sd	s2,0(sp)
    800039b6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039b8:	c905                	beqz	a0,800039e8 <iunlock+0x3c>
    800039ba:	84aa                	mv	s1,a0
    800039bc:	01050913          	addi	s2,a0,16
    800039c0:	854a                	mv	a0,s2
    800039c2:	00001097          	auipc	ra,0x1
    800039c6:	c7c080e7          	jalr	-900(ra) # 8000463e <holdingsleep>
    800039ca:	cd19                	beqz	a0,800039e8 <iunlock+0x3c>
    800039cc:	449c                	lw	a5,8(s1)
    800039ce:	00f05d63          	blez	a5,800039e8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	c26080e7          	jalr	-986(ra) # 800045fa <releasesleep>
}
    800039dc:	60e2                	ld	ra,24(sp)
    800039de:	6442                	ld	s0,16(sp)
    800039e0:	64a2                	ld	s1,8(sp)
    800039e2:	6902                	ld	s2,0(sp)
    800039e4:	6105                	addi	sp,sp,32
    800039e6:	8082                	ret
    panic("iunlock");
    800039e8:	00005517          	auipc	a0,0x5
    800039ec:	c4050513          	addi	a0,a0,-960 # 80008628 <syscalls+0x1a8>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	cd6080e7          	jalr	-810(ra) # 800006c6 <panic>

00000000800039f8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039f8:	7179                	addi	sp,sp,-48
    800039fa:	f406                	sd	ra,40(sp)
    800039fc:	f022                	sd	s0,32(sp)
    800039fe:	ec26                	sd	s1,24(sp)
    80003a00:	e84a                	sd	s2,16(sp)
    80003a02:	e44e                	sd	s3,8(sp)
    80003a04:	e052                	sd	s4,0(sp)
    80003a06:	1800                	addi	s0,sp,48
    80003a08:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a0a:	05050493          	addi	s1,a0,80
    80003a0e:	08050913          	addi	s2,a0,128
    80003a12:	a021                	j	80003a1a <itrunc+0x22>
    80003a14:	0491                	addi	s1,s1,4
    80003a16:	01248d63          	beq	s1,s2,80003a30 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a1a:	408c                	lw	a1,0(s1)
    80003a1c:	dde5                	beqz	a1,80003a14 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a1e:	0009a503          	lw	a0,0(s3)
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	8f4080e7          	jalr	-1804(ra) # 80003316 <bfree>
      ip->addrs[i] = 0;
    80003a2a:	0004a023          	sw	zero,0(s1)
    80003a2e:	b7dd                	j	80003a14 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a30:	0809a583          	lw	a1,128(s3)
    80003a34:	e185                	bnez	a1,80003a54 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a3a:	854e                	mv	a0,s3
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	de4080e7          	jalr	-540(ra) # 80003820 <iupdate>
}
    80003a44:	70a2                	ld	ra,40(sp)
    80003a46:	7402                	ld	s0,32(sp)
    80003a48:	64e2                	ld	s1,24(sp)
    80003a4a:	6942                	ld	s2,16(sp)
    80003a4c:	69a2                	ld	s3,8(sp)
    80003a4e:	6a02                	ld	s4,0(sp)
    80003a50:	6145                	addi	sp,sp,48
    80003a52:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a54:	0009a503          	lw	a0,0(s3)
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	678080e7          	jalr	1656(ra) # 800030d0 <bread>
    80003a60:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a62:	05850493          	addi	s1,a0,88
    80003a66:	45850913          	addi	s2,a0,1112
    80003a6a:	a021                	j	80003a72 <itrunc+0x7a>
    80003a6c:	0491                	addi	s1,s1,4
    80003a6e:	01248b63          	beq	s1,s2,80003a84 <itrunc+0x8c>
      if(a[j])
    80003a72:	408c                	lw	a1,0(s1)
    80003a74:	dde5                	beqz	a1,80003a6c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a76:	0009a503          	lw	a0,0(s3)
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	89c080e7          	jalr	-1892(ra) # 80003316 <bfree>
    80003a82:	b7ed                	j	80003a6c <itrunc+0x74>
    brelse(bp);
    80003a84:	8552                	mv	a0,s4
    80003a86:	fffff097          	auipc	ra,0xfffff
    80003a8a:	77a080e7          	jalr	1914(ra) # 80003200 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a8e:	0809a583          	lw	a1,128(s3)
    80003a92:	0009a503          	lw	a0,0(s3)
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	880080e7          	jalr	-1920(ra) # 80003316 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a9e:	0809a023          	sw	zero,128(s3)
    80003aa2:	bf51                	j	80003a36 <itrunc+0x3e>

0000000080003aa4 <iput>:
{
    80003aa4:	1101                	addi	sp,sp,-32
    80003aa6:	ec06                	sd	ra,24(sp)
    80003aa8:	e822                	sd	s0,16(sp)
    80003aaa:	e426                	sd	s1,8(sp)
    80003aac:	e04a                	sd	s2,0(sp)
    80003aae:	1000                	addi	s0,sp,32
    80003ab0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ab2:	0001c517          	auipc	a0,0x1c
    80003ab6:	e3650513          	addi	a0,a0,-458 # 8001f8e8 <itable>
    80003aba:	ffffd097          	auipc	ra,0xffffd
    80003abe:	2a4080e7          	jalr	676(ra) # 80000d5e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ac2:	4498                	lw	a4,8(s1)
    80003ac4:	4785                	li	a5,1
    80003ac6:	02f70363          	beq	a4,a5,80003aec <iput+0x48>
  ip->ref--;
    80003aca:	449c                	lw	a5,8(s1)
    80003acc:	37fd                	addiw	a5,a5,-1
    80003ace:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad0:	0001c517          	auipc	a0,0x1c
    80003ad4:	e1850513          	addi	a0,a0,-488 # 8001f8e8 <itable>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	33a080e7          	jalr	826(ra) # 80000e12 <release>
}
    80003ae0:	60e2                	ld	ra,24(sp)
    80003ae2:	6442                	ld	s0,16(sp)
    80003ae4:	64a2                	ld	s1,8(sp)
    80003ae6:	6902                	ld	s2,0(sp)
    80003ae8:	6105                	addi	sp,sp,32
    80003aea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aec:	40bc                	lw	a5,64(s1)
    80003aee:	dff1                	beqz	a5,80003aca <iput+0x26>
    80003af0:	04a49783          	lh	a5,74(s1)
    80003af4:	fbf9                	bnez	a5,80003aca <iput+0x26>
    acquiresleep(&ip->lock);
    80003af6:	01048913          	addi	s2,s1,16
    80003afa:	854a                	mv	a0,s2
    80003afc:	00001097          	auipc	ra,0x1
    80003b00:	aa8080e7          	jalr	-1368(ra) # 800045a4 <acquiresleep>
    release(&itable.lock);
    80003b04:	0001c517          	auipc	a0,0x1c
    80003b08:	de450513          	addi	a0,a0,-540 # 8001f8e8 <itable>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	306080e7          	jalr	774(ra) # 80000e12 <release>
    itrunc(ip);
    80003b14:	8526                	mv	a0,s1
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	ee2080e7          	jalr	-286(ra) # 800039f8 <itrunc>
    ip->type = 0;
    80003b1e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b22:	8526                	mv	a0,s1
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	cfc080e7          	jalr	-772(ra) # 80003820 <iupdate>
    ip->valid = 0;
    80003b2c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b30:	854a                	mv	a0,s2
    80003b32:	00001097          	auipc	ra,0x1
    80003b36:	ac8080e7          	jalr	-1336(ra) # 800045fa <releasesleep>
    acquire(&itable.lock);
    80003b3a:	0001c517          	auipc	a0,0x1c
    80003b3e:	dae50513          	addi	a0,a0,-594 # 8001f8e8 <itable>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	21c080e7          	jalr	540(ra) # 80000d5e <acquire>
    80003b4a:	b741                	j	80003aca <iput+0x26>

0000000080003b4c <iunlockput>:
{
    80003b4c:	1101                	addi	sp,sp,-32
    80003b4e:	ec06                	sd	ra,24(sp)
    80003b50:	e822                	sd	s0,16(sp)
    80003b52:	e426                	sd	s1,8(sp)
    80003b54:	1000                	addi	s0,sp,32
    80003b56:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	e54080e7          	jalr	-428(ra) # 800039ac <iunlock>
  iput(ip);
    80003b60:	8526                	mv	a0,s1
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	f42080e7          	jalr	-190(ra) # 80003aa4 <iput>
}
    80003b6a:	60e2                	ld	ra,24(sp)
    80003b6c:	6442                	ld	s0,16(sp)
    80003b6e:	64a2                	ld	s1,8(sp)
    80003b70:	6105                	addi	sp,sp,32
    80003b72:	8082                	ret

0000000080003b74 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b74:	1141                	addi	sp,sp,-16
    80003b76:	e422                	sd	s0,8(sp)
    80003b78:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b7a:	411c                	lw	a5,0(a0)
    80003b7c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b7e:	415c                	lw	a5,4(a0)
    80003b80:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b82:	04451783          	lh	a5,68(a0)
    80003b86:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b8a:	04a51783          	lh	a5,74(a0)
    80003b8e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b92:	04c56783          	lwu	a5,76(a0)
    80003b96:	e99c                	sd	a5,16(a1)
}
    80003b98:	6422                	ld	s0,8(sp)
    80003b9a:	0141                	addi	sp,sp,16
    80003b9c:	8082                	ret

0000000080003b9e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b9e:	457c                	lw	a5,76(a0)
    80003ba0:	0ed7e963          	bltu	a5,a3,80003c92 <readi+0xf4>
{
    80003ba4:	7159                	addi	sp,sp,-112
    80003ba6:	f486                	sd	ra,104(sp)
    80003ba8:	f0a2                	sd	s0,96(sp)
    80003baa:	eca6                	sd	s1,88(sp)
    80003bac:	e8ca                	sd	s2,80(sp)
    80003bae:	e4ce                	sd	s3,72(sp)
    80003bb0:	e0d2                	sd	s4,64(sp)
    80003bb2:	fc56                	sd	s5,56(sp)
    80003bb4:	f85a                	sd	s6,48(sp)
    80003bb6:	f45e                	sd	s7,40(sp)
    80003bb8:	f062                	sd	s8,32(sp)
    80003bba:	ec66                	sd	s9,24(sp)
    80003bbc:	e86a                	sd	s10,16(sp)
    80003bbe:	e46e                	sd	s11,8(sp)
    80003bc0:	1880                	addi	s0,sp,112
    80003bc2:	8b2a                	mv	s6,a0
    80003bc4:	8bae                	mv	s7,a1
    80003bc6:	8a32                	mv	s4,a2
    80003bc8:	84b6                	mv	s1,a3
    80003bca:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bcc:	9f35                	addw	a4,a4,a3
    return 0;
    80003bce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bd0:	0ad76063          	bltu	a4,a3,80003c70 <readi+0xd2>
  if(off + n > ip->size)
    80003bd4:	00e7f463          	bgeu	a5,a4,80003bdc <readi+0x3e>
    n = ip->size - off;
    80003bd8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bdc:	0a0a8963          	beqz	s5,80003c8e <readi+0xf0>
    80003be0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003be6:	5c7d                	li	s8,-1
    80003be8:	a82d                	j	80003c22 <readi+0x84>
    80003bea:	020d1d93          	slli	s11,s10,0x20
    80003bee:	020ddd93          	srli	s11,s11,0x20
    80003bf2:	05890793          	addi	a5,s2,88
    80003bf6:	86ee                	mv	a3,s11
    80003bf8:	963e                	add	a2,a2,a5
    80003bfa:	85d2                	mv	a1,s4
    80003bfc:	855e                	mv	a0,s7
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	9e6080e7          	jalr	-1562(ra) # 800025e4 <either_copyout>
    80003c06:	05850d63          	beq	a0,s8,80003c60 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	5f4080e7          	jalr	1524(ra) # 80003200 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c14:	013d09bb          	addw	s3,s10,s3
    80003c18:	009d04bb          	addw	s1,s10,s1
    80003c1c:	9a6e                	add	s4,s4,s11
    80003c1e:	0559f763          	bgeu	s3,s5,80003c6c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c22:	00a4d59b          	srliw	a1,s1,0xa
    80003c26:	855a                	mv	a0,s6
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	8a2080e7          	jalr	-1886(ra) # 800034ca <bmap>
    80003c30:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c34:	cd85                	beqz	a1,80003c6c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c36:	000b2503          	lw	a0,0(s6)
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	496080e7          	jalr	1174(ra) # 800030d0 <bread>
    80003c42:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c44:	3ff4f613          	andi	a2,s1,1023
    80003c48:	40cc87bb          	subw	a5,s9,a2
    80003c4c:	413a873b          	subw	a4,s5,s3
    80003c50:	8d3e                	mv	s10,a5
    80003c52:	2781                	sext.w	a5,a5
    80003c54:	0007069b          	sext.w	a3,a4
    80003c58:	f8f6f9e3          	bgeu	a3,a5,80003bea <readi+0x4c>
    80003c5c:	8d3a                	mv	s10,a4
    80003c5e:	b771                	j	80003bea <readi+0x4c>
      brelse(bp);
    80003c60:	854a                	mv	a0,s2
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	59e080e7          	jalr	1438(ra) # 80003200 <brelse>
      tot = -1;
    80003c6a:	59fd                	li	s3,-1
  }
  return tot;
    80003c6c:	0009851b          	sext.w	a0,s3
}
    80003c70:	70a6                	ld	ra,104(sp)
    80003c72:	7406                	ld	s0,96(sp)
    80003c74:	64e6                	ld	s1,88(sp)
    80003c76:	6946                	ld	s2,80(sp)
    80003c78:	69a6                	ld	s3,72(sp)
    80003c7a:	6a06                	ld	s4,64(sp)
    80003c7c:	7ae2                	ld	s5,56(sp)
    80003c7e:	7b42                	ld	s6,48(sp)
    80003c80:	7ba2                	ld	s7,40(sp)
    80003c82:	7c02                	ld	s8,32(sp)
    80003c84:	6ce2                	ld	s9,24(sp)
    80003c86:	6d42                	ld	s10,16(sp)
    80003c88:	6da2                	ld	s11,8(sp)
    80003c8a:	6165                	addi	sp,sp,112
    80003c8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c8e:	89d6                	mv	s3,s5
    80003c90:	bff1                	j	80003c6c <readi+0xce>
    return 0;
    80003c92:	4501                	li	a0,0
}
    80003c94:	8082                	ret

0000000080003c96 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c96:	457c                	lw	a5,76(a0)
    80003c98:	10d7e863          	bltu	a5,a3,80003da8 <writei+0x112>
{
    80003c9c:	7159                	addi	sp,sp,-112
    80003c9e:	f486                	sd	ra,104(sp)
    80003ca0:	f0a2                	sd	s0,96(sp)
    80003ca2:	eca6                	sd	s1,88(sp)
    80003ca4:	e8ca                	sd	s2,80(sp)
    80003ca6:	e4ce                	sd	s3,72(sp)
    80003ca8:	e0d2                	sd	s4,64(sp)
    80003caa:	fc56                	sd	s5,56(sp)
    80003cac:	f85a                	sd	s6,48(sp)
    80003cae:	f45e                	sd	s7,40(sp)
    80003cb0:	f062                	sd	s8,32(sp)
    80003cb2:	ec66                	sd	s9,24(sp)
    80003cb4:	e86a                	sd	s10,16(sp)
    80003cb6:	e46e                	sd	s11,8(sp)
    80003cb8:	1880                	addi	s0,sp,112
    80003cba:	8aaa                	mv	s5,a0
    80003cbc:	8bae                	mv	s7,a1
    80003cbe:	8a32                	mv	s4,a2
    80003cc0:	8936                	mv	s2,a3
    80003cc2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cc4:	00e687bb          	addw	a5,a3,a4
    80003cc8:	0ed7e263          	bltu	a5,a3,80003dac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ccc:	00043737          	lui	a4,0x43
    80003cd0:	0ef76063          	bltu	a4,a5,80003db0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd4:	0c0b0863          	beqz	s6,80003da4 <writei+0x10e>
    80003cd8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cda:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cde:	5c7d                	li	s8,-1
    80003ce0:	a091                	j	80003d24 <writei+0x8e>
    80003ce2:	020d1d93          	slli	s11,s10,0x20
    80003ce6:	020ddd93          	srli	s11,s11,0x20
    80003cea:	05848793          	addi	a5,s1,88
    80003cee:	86ee                	mv	a3,s11
    80003cf0:	8652                	mv	a2,s4
    80003cf2:	85de                	mv	a1,s7
    80003cf4:	953e                	add	a0,a0,a5
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	944080e7          	jalr	-1724(ra) # 8000263a <either_copyin>
    80003cfe:	07850263          	beq	a0,s8,80003d62 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d02:	8526                	mv	a0,s1
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	780080e7          	jalr	1920(ra) # 80004484 <log_write>
    brelse(bp);
    80003d0c:	8526                	mv	a0,s1
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	4f2080e7          	jalr	1266(ra) # 80003200 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d16:	013d09bb          	addw	s3,s10,s3
    80003d1a:	012d093b          	addw	s2,s10,s2
    80003d1e:	9a6e                	add	s4,s4,s11
    80003d20:	0569f663          	bgeu	s3,s6,80003d6c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d24:	00a9559b          	srliw	a1,s2,0xa
    80003d28:	8556                	mv	a0,s5
    80003d2a:	fffff097          	auipc	ra,0xfffff
    80003d2e:	7a0080e7          	jalr	1952(ra) # 800034ca <bmap>
    80003d32:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d36:	c99d                	beqz	a1,80003d6c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d38:	000aa503          	lw	a0,0(s5)
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	394080e7          	jalr	916(ra) # 800030d0 <bread>
    80003d44:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d46:	3ff97513          	andi	a0,s2,1023
    80003d4a:	40ac87bb          	subw	a5,s9,a0
    80003d4e:	413b073b          	subw	a4,s6,s3
    80003d52:	8d3e                	mv	s10,a5
    80003d54:	2781                	sext.w	a5,a5
    80003d56:	0007069b          	sext.w	a3,a4
    80003d5a:	f8f6f4e3          	bgeu	a3,a5,80003ce2 <writei+0x4c>
    80003d5e:	8d3a                	mv	s10,a4
    80003d60:	b749                	j	80003ce2 <writei+0x4c>
      brelse(bp);
    80003d62:	8526                	mv	a0,s1
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	49c080e7          	jalr	1180(ra) # 80003200 <brelse>
  }

  if(off > ip->size)
    80003d6c:	04caa783          	lw	a5,76(s5)
    80003d70:	0127f463          	bgeu	a5,s2,80003d78 <writei+0xe2>
    ip->size = off;
    80003d74:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d78:	8556                	mv	a0,s5
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	aa6080e7          	jalr	-1370(ra) # 80003820 <iupdate>

  return tot;
    80003d82:	0009851b          	sext.w	a0,s3
}
    80003d86:	70a6                	ld	ra,104(sp)
    80003d88:	7406                	ld	s0,96(sp)
    80003d8a:	64e6                	ld	s1,88(sp)
    80003d8c:	6946                	ld	s2,80(sp)
    80003d8e:	69a6                	ld	s3,72(sp)
    80003d90:	6a06                	ld	s4,64(sp)
    80003d92:	7ae2                	ld	s5,56(sp)
    80003d94:	7b42                	ld	s6,48(sp)
    80003d96:	7ba2                	ld	s7,40(sp)
    80003d98:	7c02                	ld	s8,32(sp)
    80003d9a:	6ce2                	ld	s9,24(sp)
    80003d9c:	6d42                	ld	s10,16(sp)
    80003d9e:	6da2                	ld	s11,8(sp)
    80003da0:	6165                	addi	sp,sp,112
    80003da2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da4:	89da                	mv	s3,s6
    80003da6:	bfc9                	j	80003d78 <writei+0xe2>
    return -1;
    80003da8:	557d                	li	a0,-1
}
    80003daa:	8082                	ret
    return -1;
    80003dac:	557d                	li	a0,-1
    80003dae:	bfe1                	j	80003d86 <writei+0xf0>
    return -1;
    80003db0:	557d                	li	a0,-1
    80003db2:	bfd1                	j	80003d86 <writei+0xf0>

0000000080003db4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003db4:	1141                	addi	sp,sp,-16
    80003db6:	e406                	sd	ra,8(sp)
    80003db8:	e022                	sd	s0,0(sp)
    80003dba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dbc:	4639                	li	a2,14
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	16c080e7          	jalr	364(ra) # 80000f2a <strncmp>
}
    80003dc6:	60a2                	ld	ra,8(sp)
    80003dc8:	6402                	ld	s0,0(sp)
    80003dca:	0141                	addi	sp,sp,16
    80003dcc:	8082                	ret

0000000080003dce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dce:	7139                	addi	sp,sp,-64
    80003dd0:	fc06                	sd	ra,56(sp)
    80003dd2:	f822                	sd	s0,48(sp)
    80003dd4:	f426                	sd	s1,40(sp)
    80003dd6:	f04a                	sd	s2,32(sp)
    80003dd8:	ec4e                	sd	s3,24(sp)
    80003dda:	e852                	sd	s4,16(sp)
    80003ddc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dde:	04451703          	lh	a4,68(a0)
    80003de2:	4785                	li	a5,1
    80003de4:	00f71a63          	bne	a4,a5,80003df8 <dirlookup+0x2a>
    80003de8:	892a                	mv	s2,a0
    80003dea:	89ae                	mv	s3,a1
    80003dec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dee:	457c                	lw	a5,76(a0)
    80003df0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003df2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df4:	e79d                	bnez	a5,80003e22 <dirlookup+0x54>
    80003df6:	a8a5                	j	80003e6e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003df8:	00005517          	auipc	a0,0x5
    80003dfc:	83850513          	addi	a0,a0,-1992 # 80008630 <syscalls+0x1b0>
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	8c6080e7          	jalr	-1850(ra) # 800006c6 <panic>
      panic("dirlookup read");
    80003e08:	00005517          	auipc	a0,0x5
    80003e0c:	84050513          	addi	a0,a0,-1984 # 80008648 <syscalls+0x1c8>
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	8b6080e7          	jalr	-1866(ra) # 800006c6 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e18:	24c1                	addiw	s1,s1,16
    80003e1a:	04c92783          	lw	a5,76(s2)
    80003e1e:	04f4f763          	bgeu	s1,a5,80003e6c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e22:	4741                	li	a4,16
    80003e24:	86a6                	mv	a3,s1
    80003e26:	fc040613          	addi	a2,s0,-64
    80003e2a:	4581                	li	a1,0
    80003e2c:	854a                	mv	a0,s2
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	d70080e7          	jalr	-656(ra) # 80003b9e <readi>
    80003e36:	47c1                	li	a5,16
    80003e38:	fcf518e3          	bne	a0,a5,80003e08 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e3c:	fc045783          	lhu	a5,-64(s0)
    80003e40:	dfe1                	beqz	a5,80003e18 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e42:	fc240593          	addi	a1,s0,-62
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	f6c080e7          	jalr	-148(ra) # 80003db4 <namecmp>
    80003e50:	f561                	bnez	a0,80003e18 <dirlookup+0x4a>
      if(poff)
    80003e52:	000a0463          	beqz	s4,80003e5a <dirlookup+0x8c>
        *poff = off;
    80003e56:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e5a:	fc045583          	lhu	a1,-64(s0)
    80003e5e:	00092503          	lw	a0,0(s2)
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	750080e7          	jalr	1872(ra) # 800035b2 <iget>
    80003e6a:	a011                	j	80003e6e <dirlookup+0xa0>
  return 0;
    80003e6c:	4501                	li	a0,0
}
    80003e6e:	70e2                	ld	ra,56(sp)
    80003e70:	7442                	ld	s0,48(sp)
    80003e72:	74a2                	ld	s1,40(sp)
    80003e74:	7902                	ld	s2,32(sp)
    80003e76:	69e2                	ld	s3,24(sp)
    80003e78:	6a42                	ld	s4,16(sp)
    80003e7a:	6121                	addi	sp,sp,64
    80003e7c:	8082                	ret

0000000080003e7e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e7e:	711d                	addi	sp,sp,-96
    80003e80:	ec86                	sd	ra,88(sp)
    80003e82:	e8a2                	sd	s0,80(sp)
    80003e84:	e4a6                	sd	s1,72(sp)
    80003e86:	e0ca                	sd	s2,64(sp)
    80003e88:	fc4e                	sd	s3,56(sp)
    80003e8a:	f852                	sd	s4,48(sp)
    80003e8c:	f456                	sd	s5,40(sp)
    80003e8e:	f05a                	sd	s6,32(sp)
    80003e90:	ec5e                	sd	s7,24(sp)
    80003e92:	e862                	sd	s8,16(sp)
    80003e94:	e466                	sd	s9,8(sp)
    80003e96:	1080                	addi	s0,sp,96
    80003e98:	84aa                	mv	s1,a0
    80003e9a:	8aae                	mv	s5,a1
    80003e9c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e9e:	00054703          	lbu	a4,0(a0)
    80003ea2:	02f00793          	li	a5,47
    80003ea6:	02f70363          	beq	a4,a5,80003ecc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eaa:	ffffe097          	auipc	ra,0xffffe
    80003eae:	c8a080e7          	jalr	-886(ra) # 80001b34 <myproc>
    80003eb2:	15053503          	ld	a0,336(a0)
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	9f6080e7          	jalr	-1546(ra) # 800038ac <idup>
    80003ebe:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ec0:	02f00913          	li	s2,47
  len = path - s;
    80003ec4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003ec6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ec8:	4b85                	li	s7,1
    80003eca:	a865                	j	80003f82 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ecc:	4585                	li	a1,1
    80003ece:	4505                	li	a0,1
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	6e2080e7          	jalr	1762(ra) # 800035b2 <iget>
    80003ed8:	89aa                	mv	s3,a0
    80003eda:	b7dd                	j	80003ec0 <namex+0x42>
      iunlockput(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	c6e080e7          	jalr	-914(ra) # 80003b4c <iunlockput>
      return 0;
    80003ee6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ee8:	854e                	mv	a0,s3
    80003eea:	60e6                	ld	ra,88(sp)
    80003eec:	6446                	ld	s0,80(sp)
    80003eee:	64a6                	ld	s1,72(sp)
    80003ef0:	6906                	ld	s2,64(sp)
    80003ef2:	79e2                	ld	s3,56(sp)
    80003ef4:	7a42                	ld	s4,48(sp)
    80003ef6:	7aa2                	ld	s5,40(sp)
    80003ef8:	7b02                	ld	s6,32(sp)
    80003efa:	6be2                	ld	s7,24(sp)
    80003efc:	6c42                	ld	s8,16(sp)
    80003efe:	6ca2                	ld	s9,8(sp)
    80003f00:	6125                	addi	sp,sp,96
    80003f02:	8082                	ret
      iunlock(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	aa6080e7          	jalr	-1370(ra) # 800039ac <iunlock>
      return ip;
    80003f0e:	bfe9                	j	80003ee8 <namex+0x6a>
      iunlockput(ip);
    80003f10:	854e                	mv	a0,s3
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	c3a080e7          	jalr	-966(ra) # 80003b4c <iunlockput>
      return 0;
    80003f1a:	89e6                	mv	s3,s9
    80003f1c:	b7f1                	j	80003ee8 <namex+0x6a>
  len = path - s;
    80003f1e:	40b48633          	sub	a2,s1,a1
    80003f22:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f26:	099c5463          	bge	s8,s9,80003fae <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f2a:	4639                	li	a2,14
    80003f2c:	8552                	mv	a0,s4
    80003f2e:	ffffd097          	auipc	ra,0xffffd
    80003f32:	f88080e7          	jalr	-120(ra) # 80000eb6 <memmove>
  while(*path == '/')
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	01279763          	bne	a5,s2,80003f48 <namex+0xca>
    path++;
    80003f3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	ff278de3          	beq	a5,s2,80003f3e <namex+0xc0>
    ilock(ip);
    80003f48:	854e                	mv	a0,s3
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	9a0080e7          	jalr	-1632(ra) # 800038ea <ilock>
    if(ip->type != T_DIR){
    80003f52:	04499783          	lh	a5,68(s3)
    80003f56:	f97793e3          	bne	a5,s7,80003edc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f5a:	000a8563          	beqz	s5,80003f64 <namex+0xe6>
    80003f5e:	0004c783          	lbu	a5,0(s1)
    80003f62:	d3cd                	beqz	a5,80003f04 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f64:	865a                	mv	a2,s6
    80003f66:	85d2                	mv	a1,s4
    80003f68:	854e                	mv	a0,s3
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	e64080e7          	jalr	-412(ra) # 80003dce <dirlookup>
    80003f72:	8caa                	mv	s9,a0
    80003f74:	dd51                	beqz	a0,80003f10 <namex+0x92>
    iunlockput(ip);
    80003f76:	854e                	mv	a0,s3
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	bd4080e7          	jalr	-1068(ra) # 80003b4c <iunlockput>
    ip = next;
    80003f80:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f82:	0004c783          	lbu	a5,0(s1)
    80003f86:	05279763          	bne	a5,s2,80003fd4 <namex+0x156>
    path++;
    80003f8a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f8c:	0004c783          	lbu	a5,0(s1)
    80003f90:	ff278de3          	beq	a5,s2,80003f8a <namex+0x10c>
  if(*path == 0)
    80003f94:	c79d                	beqz	a5,80003fc2 <namex+0x144>
    path++;
    80003f96:	85a6                	mv	a1,s1
  len = path - s;
    80003f98:	8cda                	mv	s9,s6
    80003f9a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f9c:	01278963          	beq	a5,s2,80003fae <namex+0x130>
    80003fa0:	dfbd                	beqz	a5,80003f1e <namex+0xa0>
    path++;
    80003fa2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fa4:	0004c783          	lbu	a5,0(s1)
    80003fa8:	ff279ce3          	bne	a5,s2,80003fa0 <namex+0x122>
    80003fac:	bf8d                	j	80003f1e <namex+0xa0>
    memmove(name, s, len);
    80003fae:	2601                	sext.w	a2,a2
    80003fb0:	8552                	mv	a0,s4
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	f04080e7          	jalr	-252(ra) # 80000eb6 <memmove>
    name[len] = 0;
    80003fba:	9cd2                	add	s9,s9,s4
    80003fbc:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fc0:	bf9d                	j	80003f36 <namex+0xb8>
  if(nameiparent){
    80003fc2:	f20a83e3          	beqz	s5,80003ee8 <namex+0x6a>
    iput(ip);
    80003fc6:	854e                	mv	a0,s3
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	adc080e7          	jalr	-1316(ra) # 80003aa4 <iput>
    return 0;
    80003fd0:	4981                	li	s3,0
    80003fd2:	bf19                	j	80003ee8 <namex+0x6a>
  if(*path == 0)
    80003fd4:	d7fd                	beqz	a5,80003fc2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fd6:	0004c783          	lbu	a5,0(s1)
    80003fda:	85a6                	mv	a1,s1
    80003fdc:	b7d1                	j	80003fa0 <namex+0x122>

0000000080003fde <dirlink>:
{
    80003fde:	7139                	addi	sp,sp,-64
    80003fe0:	fc06                	sd	ra,56(sp)
    80003fe2:	f822                	sd	s0,48(sp)
    80003fe4:	f426                	sd	s1,40(sp)
    80003fe6:	f04a                	sd	s2,32(sp)
    80003fe8:	ec4e                	sd	s3,24(sp)
    80003fea:	e852                	sd	s4,16(sp)
    80003fec:	0080                	addi	s0,sp,64
    80003fee:	892a                	mv	s2,a0
    80003ff0:	8a2e                	mv	s4,a1
    80003ff2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ff4:	4601                	li	a2,0
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	dd8080e7          	jalr	-552(ra) # 80003dce <dirlookup>
    80003ffe:	e93d                	bnez	a0,80004074 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004000:	04c92483          	lw	s1,76(s2)
    80004004:	c49d                	beqz	s1,80004032 <dirlink+0x54>
    80004006:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004008:	4741                	li	a4,16
    8000400a:	86a6                	mv	a3,s1
    8000400c:	fc040613          	addi	a2,s0,-64
    80004010:	4581                	li	a1,0
    80004012:	854a                	mv	a0,s2
    80004014:	00000097          	auipc	ra,0x0
    80004018:	b8a080e7          	jalr	-1142(ra) # 80003b9e <readi>
    8000401c:	47c1                	li	a5,16
    8000401e:	06f51163          	bne	a0,a5,80004080 <dirlink+0xa2>
    if(de.inum == 0)
    80004022:	fc045783          	lhu	a5,-64(s0)
    80004026:	c791                	beqz	a5,80004032 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004028:	24c1                	addiw	s1,s1,16
    8000402a:	04c92783          	lw	a5,76(s2)
    8000402e:	fcf4ede3          	bltu	s1,a5,80004008 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004032:	4639                	li	a2,14
    80004034:	85d2                	mv	a1,s4
    80004036:	fc240513          	addi	a0,s0,-62
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	f2c080e7          	jalr	-212(ra) # 80000f66 <strncpy>
  de.inum = inum;
    80004042:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004046:	4741                	li	a4,16
    80004048:	86a6                	mv	a3,s1
    8000404a:	fc040613          	addi	a2,s0,-64
    8000404e:	4581                	li	a1,0
    80004050:	854a                	mv	a0,s2
    80004052:	00000097          	auipc	ra,0x0
    80004056:	c44080e7          	jalr	-956(ra) # 80003c96 <writei>
    8000405a:	1541                	addi	a0,a0,-16
    8000405c:	00a03533          	snez	a0,a0
    80004060:	40a00533          	neg	a0,a0
}
    80004064:	70e2                	ld	ra,56(sp)
    80004066:	7442                	ld	s0,48(sp)
    80004068:	74a2                	ld	s1,40(sp)
    8000406a:	7902                	ld	s2,32(sp)
    8000406c:	69e2                	ld	s3,24(sp)
    8000406e:	6a42                	ld	s4,16(sp)
    80004070:	6121                	addi	sp,sp,64
    80004072:	8082                	ret
    iput(ip);
    80004074:	00000097          	auipc	ra,0x0
    80004078:	a30080e7          	jalr	-1488(ra) # 80003aa4 <iput>
    return -1;
    8000407c:	557d                	li	a0,-1
    8000407e:	b7dd                	j	80004064 <dirlink+0x86>
      panic("dirlink read");
    80004080:	00004517          	auipc	a0,0x4
    80004084:	5d850513          	addi	a0,a0,1496 # 80008658 <syscalls+0x1d8>
    80004088:	ffffc097          	auipc	ra,0xffffc
    8000408c:	63e080e7          	jalr	1598(ra) # 800006c6 <panic>

0000000080004090 <namei>:

struct inode*
namei(char *path)
{
    80004090:	1101                	addi	sp,sp,-32
    80004092:	ec06                	sd	ra,24(sp)
    80004094:	e822                	sd	s0,16(sp)
    80004096:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004098:	fe040613          	addi	a2,s0,-32
    8000409c:	4581                	li	a1,0
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	de0080e7          	jalr	-544(ra) # 80003e7e <namex>
}
    800040a6:	60e2                	ld	ra,24(sp)
    800040a8:	6442                	ld	s0,16(sp)
    800040aa:	6105                	addi	sp,sp,32
    800040ac:	8082                	ret

00000000800040ae <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040ae:	1141                	addi	sp,sp,-16
    800040b0:	e406                	sd	ra,8(sp)
    800040b2:	e022                	sd	s0,0(sp)
    800040b4:	0800                	addi	s0,sp,16
    800040b6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040b8:	4585                	li	a1,1
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	dc4080e7          	jalr	-572(ra) # 80003e7e <namex>
}
    800040c2:	60a2                	ld	ra,8(sp)
    800040c4:	6402                	ld	s0,0(sp)
    800040c6:	0141                	addi	sp,sp,16
    800040c8:	8082                	ret

00000000800040ca <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040ca:	1101                	addi	sp,sp,-32
    800040cc:	ec06                	sd	ra,24(sp)
    800040ce:	e822                	sd	s0,16(sp)
    800040d0:	e426                	sd	s1,8(sp)
    800040d2:	e04a                	sd	s2,0(sp)
    800040d4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040d6:	0001d917          	auipc	s2,0x1d
    800040da:	2ba90913          	addi	s2,s2,698 # 80021390 <log>
    800040de:	01892583          	lw	a1,24(s2)
    800040e2:	02892503          	lw	a0,40(s2)
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	fea080e7          	jalr	-22(ra) # 800030d0 <bread>
    800040ee:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040f0:	02c92683          	lw	a3,44(s2)
    800040f4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040f6:	02d05763          	blez	a3,80004124 <write_head+0x5a>
    800040fa:	0001d797          	auipc	a5,0x1d
    800040fe:	2c678793          	addi	a5,a5,710 # 800213c0 <log+0x30>
    80004102:	05c50713          	addi	a4,a0,92
    80004106:	36fd                	addiw	a3,a3,-1
    80004108:	1682                	slli	a3,a3,0x20
    8000410a:	9281                	srli	a3,a3,0x20
    8000410c:	068a                	slli	a3,a3,0x2
    8000410e:	0001d617          	auipc	a2,0x1d
    80004112:	2b660613          	addi	a2,a2,694 # 800213c4 <log+0x34>
    80004116:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004118:	4390                	lw	a2,0(a5)
    8000411a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000411c:	0791                	addi	a5,a5,4
    8000411e:	0711                	addi	a4,a4,4
    80004120:	fed79ce3          	bne	a5,a3,80004118 <write_head+0x4e>
  }
  bwrite(buf);
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	09c080e7          	jalr	156(ra) # 800031c2 <bwrite>
  brelse(buf);
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	0d0080e7          	jalr	208(ra) # 80003200 <brelse>
}
    80004138:	60e2                	ld	ra,24(sp)
    8000413a:	6442                	ld	s0,16(sp)
    8000413c:	64a2                	ld	s1,8(sp)
    8000413e:	6902                	ld	s2,0(sp)
    80004140:	6105                	addi	sp,sp,32
    80004142:	8082                	ret

0000000080004144 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004144:	0001d797          	auipc	a5,0x1d
    80004148:	2787a783          	lw	a5,632(a5) # 800213bc <log+0x2c>
    8000414c:	0af05d63          	blez	a5,80004206 <install_trans+0xc2>
{
    80004150:	7139                	addi	sp,sp,-64
    80004152:	fc06                	sd	ra,56(sp)
    80004154:	f822                	sd	s0,48(sp)
    80004156:	f426                	sd	s1,40(sp)
    80004158:	f04a                	sd	s2,32(sp)
    8000415a:	ec4e                	sd	s3,24(sp)
    8000415c:	e852                	sd	s4,16(sp)
    8000415e:	e456                	sd	s5,8(sp)
    80004160:	e05a                	sd	s6,0(sp)
    80004162:	0080                	addi	s0,sp,64
    80004164:	8b2a                	mv	s6,a0
    80004166:	0001da97          	auipc	s5,0x1d
    8000416a:	25aa8a93          	addi	s5,s5,602 # 800213c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004170:	0001d997          	auipc	s3,0x1d
    80004174:	22098993          	addi	s3,s3,544 # 80021390 <log>
    80004178:	a00d                	j	8000419a <install_trans+0x56>
    brelse(lbuf);
    8000417a:	854a                	mv	a0,s2
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	084080e7          	jalr	132(ra) # 80003200 <brelse>
    brelse(dbuf);
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	07a080e7          	jalr	122(ra) # 80003200 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418e:	2a05                	addiw	s4,s4,1
    80004190:	0a91                	addi	s5,s5,4
    80004192:	02c9a783          	lw	a5,44(s3)
    80004196:	04fa5e63          	bge	s4,a5,800041f2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000419a:	0189a583          	lw	a1,24(s3)
    8000419e:	014585bb          	addw	a1,a1,s4
    800041a2:	2585                	addiw	a1,a1,1
    800041a4:	0289a503          	lw	a0,40(s3)
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	f28080e7          	jalr	-216(ra) # 800030d0 <bread>
    800041b0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041b2:	000aa583          	lw	a1,0(s5)
    800041b6:	0289a503          	lw	a0,40(s3)
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	f16080e7          	jalr	-234(ra) # 800030d0 <bread>
    800041c2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041c4:	40000613          	li	a2,1024
    800041c8:	05890593          	addi	a1,s2,88
    800041cc:	05850513          	addi	a0,a0,88
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ce6080e7          	jalr	-794(ra) # 80000eb6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	fe8080e7          	jalr	-24(ra) # 800031c2 <bwrite>
    if(recovering == 0)
    800041e2:	f80b1ce3          	bnez	s6,8000417a <install_trans+0x36>
      bunpin(dbuf);
    800041e6:	8526                	mv	a0,s1
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	0f2080e7          	jalr	242(ra) # 800032da <bunpin>
    800041f0:	b769                	j	8000417a <install_trans+0x36>
}
    800041f2:	70e2                	ld	ra,56(sp)
    800041f4:	7442                	ld	s0,48(sp)
    800041f6:	74a2                	ld	s1,40(sp)
    800041f8:	7902                	ld	s2,32(sp)
    800041fa:	69e2                	ld	s3,24(sp)
    800041fc:	6a42                	ld	s4,16(sp)
    800041fe:	6aa2                	ld	s5,8(sp)
    80004200:	6b02                	ld	s6,0(sp)
    80004202:	6121                	addi	sp,sp,64
    80004204:	8082                	ret
    80004206:	8082                	ret

0000000080004208 <initlog>:
{
    80004208:	7179                	addi	sp,sp,-48
    8000420a:	f406                	sd	ra,40(sp)
    8000420c:	f022                	sd	s0,32(sp)
    8000420e:	ec26                	sd	s1,24(sp)
    80004210:	e84a                	sd	s2,16(sp)
    80004212:	e44e                	sd	s3,8(sp)
    80004214:	1800                	addi	s0,sp,48
    80004216:	892a                	mv	s2,a0
    80004218:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000421a:	0001d497          	auipc	s1,0x1d
    8000421e:	17648493          	addi	s1,s1,374 # 80021390 <log>
    80004222:	00004597          	auipc	a1,0x4
    80004226:	44658593          	addi	a1,a1,1094 # 80008668 <syscalls+0x1e8>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	aa2080e7          	jalr	-1374(ra) # 80000cce <initlock>
  log.start = sb->logstart;
    80004234:	0149a583          	lw	a1,20(s3)
    80004238:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000423a:	0109a783          	lw	a5,16(s3)
    8000423e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004240:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004244:	854a                	mv	a0,s2
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	e8a080e7          	jalr	-374(ra) # 800030d0 <bread>
  log.lh.n = lh->n;
    8000424e:	4d34                	lw	a3,88(a0)
    80004250:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004252:	02d05563          	blez	a3,8000427c <initlog+0x74>
    80004256:	05c50793          	addi	a5,a0,92
    8000425a:	0001d717          	auipc	a4,0x1d
    8000425e:	16670713          	addi	a4,a4,358 # 800213c0 <log+0x30>
    80004262:	36fd                	addiw	a3,a3,-1
    80004264:	1682                	slli	a3,a3,0x20
    80004266:	9281                	srli	a3,a3,0x20
    80004268:	068a                	slli	a3,a3,0x2
    8000426a:	06050613          	addi	a2,a0,96
    8000426e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004270:	4390                	lw	a2,0(a5)
    80004272:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004274:	0791                	addi	a5,a5,4
    80004276:	0711                	addi	a4,a4,4
    80004278:	fed79ce3          	bne	a5,a3,80004270 <initlog+0x68>
  brelse(buf);
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	f84080e7          	jalr	-124(ra) # 80003200 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004284:	4505                	li	a0,1
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	ebe080e7          	jalr	-322(ra) # 80004144 <install_trans>
  log.lh.n = 0;
    8000428e:	0001d797          	auipc	a5,0x1d
    80004292:	1207a723          	sw	zero,302(a5) # 800213bc <log+0x2c>
  write_head(); // clear the log
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	e34080e7          	jalr	-460(ra) # 800040ca <write_head>
}
    8000429e:	70a2                	ld	ra,40(sp)
    800042a0:	7402                	ld	s0,32(sp)
    800042a2:	64e2                	ld	s1,24(sp)
    800042a4:	6942                	ld	s2,16(sp)
    800042a6:	69a2                	ld	s3,8(sp)
    800042a8:	6145                	addi	sp,sp,48
    800042aa:	8082                	ret

00000000800042ac <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042ac:	1101                	addi	sp,sp,-32
    800042ae:	ec06                	sd	ra,24(sp)
    800042b0:	e822                	sd	s0,16(sp)
    800042b2:	e426                	sd	s1,8(sp)
    800042b4:	e04a                	sd	s2,0(sp)
    800042b6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042b8:	0001d517          	auipc	a0,0x1d
    800042bc:	0d850513          	addi	a0,a0,216 # 80021390 <log>
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	a9e080e7          	jalr	-1378(ra) # 80000d5e <acquire>
  while(1){
    if(log.committing){
    800042c8:	0001d497          	auipc	s1,0x1d
    800042cc:	0c848493          	addi	s1,s1,200 # 80021390 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d0:	4979                	li	s2,30
    800042d2:	a039                	j	800042e0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042d4:	85a6                	mv	a1,s1
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffe097          	auipc	ra,0xffffe
    800042dc:	f04080e7          	jalr	-252(ra) # 800021dc <sleep>
    if(log.committing){
    800042e0:	50dc                	lw	a5,36(s1)
    800042e2:	fbed                	bnez	a5,800042d4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e4:	509c                	lw	a5,32(s1)
    800042e6:	0017871b          	addiw	a4,a5,1
    800042ea:	0007069b          	sext.w	a3,a4
    800042ee:	0027179b          	slliw	a5,a4,0x2
    800042f2:	9fb9                	addw	a5,a5,a4
    800042f4:	0017979b          	slliw	a5,a5,0x1
    800042f8:	54d8                	lw	a4,44(s1)
    800042fa:	9fb9                	addw	a5,a5,a4
    800042fc:	00f95963          	bge	s2,a5,8000430e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004300:	85a6                	mv	a1,s1
    80004302:	8526                	mv	a0,s1
    80004304:	ffffe097          	auipc	ra,0xffffe
    80004308:	ed8080e7          	jalr	-296(ra) # 800021dc <sleep>
    8000430c:	bfd1                	j	800042e0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000430e:	0001d517          	auipc	a0,0x1d
    80004312:	08250513          	addi	a0,a0,130 # 80021390 <log>
    80004316:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	afa080e7          	jalr	-1286(ra) # 80000e12 <release>
      break;
    }
  }
}
    80004320:	60e2                	ld	ra,24(sp)
    80004322:	6442                	ld	s0,16(sp)
    80004324:	64a2                	ld	s1,8(sp)
    80004326:	6902                	ld	s2,0(sp)
    80004328:	6105                	addi	sp,sp,32
    8000432a:	8082                	ret

000000008000432c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000432c:	7139                	addi	sp,sp,-64
    8000432e:	fc06                	sd	ra,56(sp)
    80004330:	f822                	sd	s0,48(sp)
    80004332:	f426                	sd	s1,40(sp)
    80004334:	f04a                	sd	s2,32(sp)
    80004336:	ec4e                	sd	s3,24(sp)
    80004338:	e852                	sd	s4,16(sp)
    8000433a:	e456                	sd	s5,8(sp)
    8000433c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000433e:	0001d497          	auipc	s1,0x1d
    80004342:	05248493          	addi	s1,s1,82 # 80021390 <log>
    80004346:	8526                	mv	a0,s1
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	a16080e7          	jalr	-1514(ra) # 80000d5e <acquire>
  log.outstanding -= 1;
    80004350:	509c                	lw	a5,32(s1)
    80004352:	37fd                	addiw	a5,a5,-1
    80004354:	0007891b          	sext.w	s2,a5
    80004358:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000435a:	50dc                	lw	a5,36(s1)
    8000435c:	e7b9                	bnez	a5,800043aa <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000435e:	04091e63          	bnez	s2,800043ba <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004362:	0001d497          	auipc	s1,0x1d
    80004366:	02e48493          	addi	s1,s1,46 # 80021390 <log>
    8000436a:	4785                	li	a5,1
    8000436c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	aa2080e7          	jalr	-1374(ra) # 80000e12 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004378:	54dc                	lw	a5,44(s1)
    8000437a:	06f04763          	bgtz	a5,800043e8 <end_op+0xbc>
    acquire(&log.lock);
    8000437e:	0001d497          	auipc	s1,0x1d
    80004382:	01248493          	addi	s1,s1,18 # 80021390 <log>
    80004386:	8526                	mv	a0,s1
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	9d6080e7          	jalr	-1578(ra) # 80000d5e <acquire>
    log.committing = 0;
    80004390:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004394:	8526                	mv	a0,s1
    80004396:	ffffe097          	auipc	ra,0xffffe
    8000439a:	eaa080e7          	jalr	-342(ra) # 80002240 <wakeup>
    release(&log.lock);
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffd097          	auipc	ra,0xffffd
    800043a4:	a72080e7          	jalr	-1422(ra) # 80000e12 <release>
}
    800043a8:	a03d                	j	800043d6 <end_op+0xaa>
    panic("log.committing");
    800043aa:	00004517          	auipc	a0,0x4
    800043ae:	2c650513          	addi	a0,a0,710 # 80008670 <syscalls+0x1f0>
    800043b2:	ffffc097          	auipc	ra,0xffffc
    800043b6:	314080e7          	jalr	788(ra) # 800006c6 <panic>
    wakeup(&log);
    800043ba:	0001d497          	auipc	s1,0x1d
    800043be:	fd648493          	addi	s1,s1,-42 # 80021390 <log>
    800043c2:	8526                	mv	a0,s1
    800043c4:	ffffe097          	auipc	ra,0xffffe
    800043c8:	e7c080e7          	jalr	-388(ra) # 80002240 <wakeup>
  release(&log.lock);
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	a44080e7          	jalr	-1468(ra) # 80000e12 <release>
}
    800043d6:	70e2                	ld	ra,56(sp)
    800043d8:	7442                	ld	s0,48(sp)
    800043da:	74a2                	ld	s1,40(sp)
    800043dc:	7902                	ld	s2,32(sp)
    800043de:	69e2                	ld	s3,24(sp)
    800043e0:	6a42                	ld	s4,16(sp)
    800043e2:	6aa2                	ld	s5,8(sp)
    800043e4:	6121                	addi	sp,sp,64
    800043e6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e8:	0001da97          	auipc	s5,0x1d
    800043ec:	fd8a8a93          	addi	s5,s5,-40 # 800213c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043f0:	0001da17          	auipc	s4,0x1d
    800043f4:	fa0a0a13          	addi	s4,s4,-96 # 80021390 <log>
    800043f8:	018a2583          	lw	a1,24(s4)
    800043fc:	012585bb          	addw	a1,a1,s2
    80004400:	2585                	addiw	a1,a1,1
    80004402:	028a2503          	lw	a0,40(s4)
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	cca080e7          	jalr	-822(ra) # 800030d0 <bread>
    8000440e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004410:	000aa583          	lw	a1,0(s5)
    80004414:	028a2503          	lw	a0,40(s4)
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	cb8080e7          	jalr	-840(ra) # 800030d0 <bread>
    80004420:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004422:	40000613          	li	a2,1024
    80004426:	05850593          	addi	a1,a0,88
    8000442a:	05848513          	addi	a0,s1,88
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	a88080e7          	jalr	-1400(ra) # 80000eb6 <memmove>
    bwrite(to);  // write the log
    80004436:	8526                	mv	a0,s1
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	d8a080e7          	jalr	-630(ra) # 800031c2 <bwrite>
    brelse(from);
    80004440:	854e                	mv	a0,s3
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	dbe080e7          	jalr	-578(ra) # 80003200 <brelse>
    brelse(to);
    8000444a:	8526                	mv	a0,s1
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	db4080e7          	jalr	-588(ra) # 80003200 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004454:	2905                	addiw	s2,s2,1
    80004456:	0a91                	addi	s5,s5,4
    80004458:	02ca2783          	lw	a5,44(s4)
    8000445c:	f8f94ee3          	blt	s2,a5,800043f8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004460:	00000097          	auipc	ra,0x0
    80004464:	c6a080e7          	jalr	-918(ra) # 800040ca <write_head>
    install_trans(0); // Now install writes to home locations
    80004468:	4501                	li	a0,0
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	cda080e7          	jalr	-806(ra) # 80004144 <install_trans>
    log.lh.n = 0;
    80004472:	0001d797          	auipc	a5,0x1d
    80004476:	f407a523          	sw	zero,-182(a5) # 800213bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	c50080e7          	jalr	-944(ra) # 800040ca <write_head>
    80004482:	bdf5                	j	8000437e <end_op+0x52>

0000000080004484 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004484:	1101                	addi	sp,sp,-32
    80004486:	ec06                	sd	ra,24(sp)
    80004488:	e822                	sd	s0,16(sp)
    8000448a:	e426                	sd	s1,8(sp)
    8000448c:	e04a                	sd	s2,0(sp)
    8000448e:	1000                	addi	s0,sp,32
    80004490:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004492:	0001d917          	auipc	s2,0x1d
    80004496:	efe90913          	addi	s2,s2,-258 # 80021390 <log>
    8000449a:	854a                	mv	a0,s2
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	8c2080e7          	jalr	-1854(ra) # 80000d5e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044a4:	02c92603          	lw	a2,44(s2)
    800044a8:	47f5                	li	a5,29
    800044aa:	06c7c563          	blt	a5,a2,80004514 <log_write+0x90>
    800044ae:	0001d797          	auipc	a5,0x1d
    800044b2:	efe7a783          	lw	a5,-258(a5) # 800213ac <log+0x1c>
    800044b6:	37fd                	addiw	a5,a5,-1
    800044b8:	04f65e63          	bge	a2,a5,80004514 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044bc:	0001d797          	auipc	a5,0x1d
    800044c0:	ef47a783          	lw	a5,-268(a5) # 800213b0 <log+0x20>
    800044c4:	06f05063          	blez	a5,80004524 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044c8:	4781                	li	a5,0
    800044ca:	06c05563          	blez	a2,80004534 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044ce:	44cc                	lw	a1,12(s1)
    800044d0:	0001d717          	auipc	a4,0x1d
    800044d4:	ef070713          	addi	a4,a4,-272 # 800213c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044d8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044da:	4314                	lw	a3,0(a4)
    800044dc:	04b68c63          	beq	a3,a1,80004534 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044e0:	2785                	addiw	a5,a5,1
    800044e2:	0711                	addi	a4,a4,4
    800044e4:	fef61be3          	bne	a2,a5,800044da <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044e8:	0621                	addi	a2,a2,8
    800044ea:	060a                	slli	a2,a2,0x2
    800044ec:	0001d797          	auipc	a5,0x1d
    800044f0:	ea478793          	addi	a5,a5,-348 # 80021390 <log>
    800044f4:	963e                	add	a2,a2,a5
    800044f6:	44dc                	lw	a5,12(s1)
    800044f8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044fa:	8526                	mv	a0,s1
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	da2080e7          	jalr	-606(ra) # 8000329e <bpin>
    log.lh.n++;
    80004504:	0001d717          	auipc	a4,0x1d
    80004508:	e8c70713          	addi	a4,a4,-372 # 80021390 <log>
    8000450c:	575c                	lw	a5,44(a4)
    8000450e:	2785                	addiw	a5,a5,1
    80004510:	d75c                	sw	a5,44(a4)
    80004512:	a835                	j	8000454e <log_write+0xca>
    panic("too big a transaction");
    80004514:	00004517          	auipc	a0,0x4
    80004518:	16c50513          	addi	a0,a0,364 # 80008680 <syscalls+0x200>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	1aa080e7          	jalr	426(ra) # 800006c6 <panic>
    panic("log_write outside of trans");
    80004524:	00004517          	auipc	a0,0x4
    80004528:	17450513          	addi	a0,a0,372 # 80008698 <syscalls+0x218>
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	19a080e7          	jalr	410(ra) # 800006c6 <panic>
  log.lh.block[i] = b->blockno;
    80004534:	00878713          	addi	a4,a5,8
    80004538:	00271693          	slli	a3,a4,0x2
    8000453c:	0001d717          	auipc	a4,0x1d
    80004540:	e5470713          	addi	a4,a4,-428 # 80021390 <log>
    80004544:	9736                	add	a4,a4,a3
    80004546:	44d4                	lw	a3,12(s1)
    80004548:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000454a:	faf608e3          	beq	a2,a5,800044fa <log_write+0x76>
  }
  release(&log.lock);
    8000454e:	0001d517          	auipc	a0,0x1d
    80004552:	e4250513          	addi	a0,a0,-446 # 80021390 <log>
    80004556:	ffffd097          	auipc	ra,0xffffd
    8000455a:	8bc080e7          	jalr	-1860(ra) # 80000e12 <release>
}
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6902                	ld	s2,0(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret

000000008000456a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	e04a                	sd	s2,0(sp)
    80004574:	1000                	addi	s0,sp,32
    80004576:	84aa                	mv	s1,a0
    80004578:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000457a:	00004597          	auipc	a1,0x4
    8000457e:	13e58593          	addi	a1,a1,318 # 800086b8 <syscalls+0x238>
    80004582:	0521                	addi	a0,a0,8
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	74a080e7          	jalr	1866(ra) # 80000cce <initlock>
  lk->name = name;
    8000458c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004590:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004594:	0204a423          	sw	zero,40(s1)
}
    80004598:	60e2                	ld	ra,24(sp)
    8000459a:	6442                	ld	s0,16(sp)
    8000459c:	64a2                	ld	s1,8(sp)
    8000459e:	6902                	ld	s2,0(sp)
    800045a0:	6105                	addi	sp,sp,32
    800045a2:	8082                	ret

00000000800045a4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045a4:	1101                	addi	sp,sp,-32
    800045a6:	ec06                	sd	ra,24(sp)
    800045a8:	e822                	sd	s0,16(sp)
    800045aa:	e426                	sd	s1,8(sp)
    800045ac:	e04a                	sd	s2,0(sp)
    800045ae:	1000                	addi	s0,sp,32
    800045b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b2:	00850913          	addi	s2,a0,8
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	7a6080e7          	jalr	1958(ra) # 80000d5e <acquire>
  while (lk->locked) {
    800045c0:	409c                	lw	a5,0(s1)
    800045c2:	cb89                	beqz	a5,800045d4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045c4:	85ca                	mv	a1,s2
    800045c6:	8526                	mv	a0,s1
    800045c8:	ffffe097          	auipc	ra,0xffffe
    800045cc:	c14080e7          	jalr	-1004(ra) # 800021dc <sleep>
  while (lk->locked) {
    800045d0:	409c                	lw	a5,0(s1)
    800045d2:	fbed                	bnez	a5,800045c4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045d4:	4785                	li	a5,1
    800045d6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045d8:	ffffd097          	auipc	ra,0xffffd
    800045dc:	55c080e7          	jalr	1372(ra) # 80001b34 <myproc>
    800045e0:	591c                	lw	a5,48(a0)
    800045e2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045e4:	854a                	mv	a0,s2
    800045e6:	ffffd097          	auipc	ra,0xffffd
    800045ea:	82c080e7          	jalr	-2004(ra) # 80000e12 <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045fa:	1101                	addi	sp,sp,-32
    800045fc:	ec06                	sd	ra,24(sp)
    800045fe:	e822                	sd	s0,16(sp)
    80004600:	e426                	sd	s1,8(sp)
    80004602:	e04a                	sd	s2,0(sp)
    80004604:	1000                	addi	s0,sp,32
    80004606:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004608:	00850913          	addi	s2,a0,8
    8000460c:	854a                	mv	a0,s2
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	750080e7          	jalr	1872(ra) # 80000d5e <acquire>
  lk->locked = 0;
    80004616:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000461a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000461e:	8526                	mv	a0,s1
    80004620:	ffffe097          	auipc	ra,0xffffe
    80004624:	c20080e7          	jalr	-992(ra) # 80002240 <wakeup>
  release(&lk->lk);
    80004628:	854a                	mv	a0,s2
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	7e8080e7          	jalr	2024(ra) # 80000e12 <release>
}
    80004632:	60e2                	ld	ra,24(sp)
    80004634:	6442                	ld	s0,16(sp)
    80004636:	64a2                	ld	s1,8(sp)
    80004638:	6902                	ld	s2,0(sp)
    8000463a:	6105                	addi	sp,sp,32
    8000463c:	8082                	ret

000000008000463e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000463e:	7179                	addi	sp,sp,-48
    80004640:	f406                	sd	ra,40(sp)
    80004642:	f022                	sd	s0,32(sp)
    80004644:	ec26                	sd	s1,24(sp)
    80004646:	e84a                	sd	s2,16(sp)
    80004648:	e44e                	sd	s3,8(sp)
    8000464a:	1800                	addi	s0,sp,48
    8000464c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000464e:	00850913          	addi	s2,a0,8
    80004652:	854a                	mv	a0,s2
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	70a080e7          	jalr	1802(ra) # 80000d5e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000465c:	409c                	lw	a5,0(s1)
    8000465e:	ef99                	bnez	a5,8000467c <holdingsleep+0x3e>
    80004660:	4481                	li	s1,0
  release(&lk->lk);
    80004662:	854a                	mv	a0,s2
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	7ae080e7          	jalr	1966(ra) # 80000e12 <release>
  return r;
}
    8000466c:	8526                	mv	a0,s1
    8000466e:	70a2                	ld	ra,40(sp)
    80004670:	7402                	ld	s0,32(sp)
    80004672:	64e2                	ld	s1,24(sp)
    80004674:	6942                	ld	s2,16(sp)
    80004676:	69a2                	ld	s3,8(sp)
    80004678:	6145                	addi	sp,sp,48
    8000467a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000467c:	0284a983          	lw	s3,40(s1)
    80004680:	ffffd097          	auipc	ra,0xffffd
    80004684:	4b4080e7          	jalr	1204(ra) # 80001b34 <myproc>
    80004688:	5904                	lw	s1,48(a0)
    8000468a:	413484b3          	sub	s1,s1,s3
    8000468e:	0014b493          	seqz	s1,s1
    80004692:	bfc1                	j	80004662 <holdingsleep+0x24>

0000000080004694 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004694:	1141                	addi	sp,sp,-16
    80004696:	e406                	sd	ra,8(sp)
    80004698:	e022                	sd	s0,0(sp)
    8000469a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000469c:	00004597          	auipc	a1,0x4
    800046a0:	02c58593          	addi	a1,a1,44 # 800086c8 <syscalls+0x248>
    800046a4:	0001d517          	auipc	a0,0x1d
    800046a8:	e3450513          	addi	a0,a0,-460 # 800214d8 <ftable>
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	622080e7          	jalr	1570(ra) # 80000cce <initlock>
}
    800046b4:	60a2                	ld	ra,8(sp)
    800046b6:	6402                	ld	s0,0(sp)
    800046b8:	0141                	addi	sp,sp,16
    800046ba:	8082                	ret

00000000800046bc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046bc:	1101                	addi	sp,sp,-32
    800046be:	ec06                	sd	ra,24(sp)
    800046c0:	e822                	sd	s0,16(sp)
    800046c2:	e426                	sd	s1,8(sp)
    800046c4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046c6:	0001d517          	auipc	a0,0x1d
    800046ca:	e1250513          	addi	a0,a0,-494 # 800214d8 <ftable>
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	690080e7          	jalr	1680(ra) # 80000d5e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d6:	0001d497          	auipc	s1,0x1d
    800046da:	e1a48493          	addi	s1,s1,-486 # 800214f0 <ftable+0x18>
    800046de:	0001e717          	auipc	a4,0x1e
    800046e2:	db270713          	addi	a4,a4,-590 # 80022490 <disk>
    if(f->ref == 0){
    800046e6:	40dc                	lw	a5,4(s1)
    800046e8:	cf99                	beqz	a5,80004706 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ea:	02848493          	addi	s1,s1,40
    800046ee:	fee49ce3          	bne	s1,a4,800046e6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046f2:	0001d517          	auipc	a0,0x1d
    800046f6:	de650513          	addi	a0,a0,-538 # 800214d8 <ftable>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	718080e7          	jalr	1816(ra) # 80000e12 <release>
  return 0;
    80004702:	4481                	li	s1,0
    80004704:	a819                	j	8000471a <filealloc+0x5e>
      f->ref = 1;
    80004706:	4785                	li	a5,1
    80004708:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000470a:	0001d517          	auipc	a0,0x1d
    8000470e:	dce50513          	addi	a0,a0,-562 # 800214d8 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	700080e7          	jalr	1792(ra) # 80000e12 <release>
}
    8000471a:	8526                	mv	a0,s1
    8000471c:	60e2                	ld	ra,24(sp)
    8000471e:	6442                	ld	s0,16(sp)
    80004720:	64a2                	ld	s1,8(sp)
    80004722:	6105                	addi	sp,sp,32
    80004724:	8082                	ret

0000000080004726 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004726:	1101                	addi	sp,sp,-32
    80004728:	ec06                	sd	ra,24(sp)
    8000472a:	e822                	sd	s0,16(sp)
    8000472c:	e426                	sd	s1,8(sp)
    8000472e:	1000                	addi	s0,sp,32
    80004730:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004732:	0001d517          	auipc	a0,0x1d
    80004736:	da650513          	addi	a0,a0,-602 # 800214d8 <ftable>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	624080e7          	jalr	1572(ra) # 80000d5e <acquire>
  if(f->ref < 1)
    80004742:	40dc                	lw	a5,4(s1)
    80004744:	02f05263          	blez	a5,80004768 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004748:	2785                	addiw	a5,a5,1
    8000474a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000474c:	0001d517          	auipc	a0,0x1d
    80004750:	d8c50513          	addi	a0,a0,-628 # 800214d8 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	6be080e7          	jalr	1726(ra) # 80000e12 <release>
  return f;
}
    8000475c:	8526                	mv	a0,s1
    8000475e:	60e2                	ld	ra,24(sp)
    80004760:	6442                	ld	s0,16(sp)
    80004762:	64a2                	ld	s1,8(sp)
    80004764:	6105                	addi	sp,sp,32
    80004766:	8082                	ret
    panic("filedup");
    80004768:	00004517          	auipc	a0,0x4
    8000476c:	f6850513          	addi	a0,a0,-152 # 800086d0 <syscalls+0x250>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	f56080e7          	jalr	-170(ra) # 800006c6 <panic>

0000000080004778 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004778:	7139                	addi	sp,sp,-64
    8000477a:	fc06                	sd	ra,56(sp)
    8000477c:	f822                	sd	s0,48(sp)
    8000477e:	f426                	sd	s1,40(sp)
    80004780:	f04a                	sd	s2,32(sp)
    80004782:	ec4e                	sd	s3,24(sp)
    80004784:	e852                	sd	s4,16(sp)
    80004786:	e456                	sd	s5,8(sp)
    80004788:	0080                	addi	s0,sp,64
    8000478a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000478c:	0001d517          	auipc	a0,0x1d
    80004790:	d4c50513          	addi	a0,a0,-692 # 800214d8 <ftable>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	5ca080e7          	jalr	1482(ra) # 80000d5e <acquire>
  if(f->ref < 1)
    8000479c:	40dc                	lw	a5,4(s1)
    8000479e:	06f05163          	blez	a5,80004800 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047a2:	37fd                	addiw	a5,a5,-1
    800047a4:	0007871b          	sext.w	a4,a5
    800047a8:	c0dc                	sw	a5,4(s1)
    800047aa:	06e04363          	bgtz	a4,80004810 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047ae:	0004a903          	lw	s2,0(s1)
    800047b2:	0094ca83          	lbu	s5,9(s1)
    800047b6:	0104ba03          	ld	s4,16(s1)
    800047ba:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047be:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047c2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	d1250513          	addi	a0,a0,-750 # 800214d8 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	644080e7          	jalr	1604(ra) # 80000e12 <release>

  if(ff.type == FD_PIPE){
    800047d6:	4785                	li	a5,1
    800047d8:	04f90d63          	beq	s2,a5,80004832 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047dc:	3979                	addiw	s2,s2,-2
    800047de:	4785                	li	a5,1
    800047e0:	0527e063          	bltu	a5,s2,80004820 <fileclose+0xa8>
    begin_op();
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	ac8080e7          	jalr	-1336(ra) # 800042ac <begin_op>
    iput(ff.ip);
    800047ec:	854e                	mv	a0,s3
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	2b6080e7          	jalr	694(ra) # 80003aa4 <iput>
    end_op();
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	b36080e7          	jalr	-1226(ra) # 8000432c <end_op>
    800047fe:	a00d                	j	80004820 <fileclose+0xa8>
    panic("fileclose");
    80004800:	00004517          	auipc	a0,0x4
    80004804:	ed850513          	addi	a0,a0,-296 # 800086d8 <syscalls+0x258>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	ebe080e7          	jalr	-322(ra) # 800006c6 <panic>
    release(&ftable.lock);
    80004810:	0001d517          	auipc	a0,0x1d
    80004814:	cc850513          	addi	a0,a0,-824 # 800214d8 <ftable>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	5fa080e7          	jalr	1530(ra) # 80000e12 <release>
  }
}
    80004820:	70e2                	ld	ra,56(sp)
    80004822:	7442                	ld	s0,48(sp)
    80004824:	74a2                	ld	s1,40(sp)
    80004826:	7902                	ld	s2,32(sp)
    80004828:	69e2                	ld	s3,24(sp)
    8000482a:	6a42                	ld	s4,16(sp)
    8000482c:	6aa2                	ld	s5,8(sp)
    8000482e:	6121                	addi	sp,sp,64
    80004830:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004832:	85d6                	mv	a1,s5
    80004834:	8552                	mv	a0,s4
    80004836:	00000097          	auipc	ra,0x0
    8000483a:	34c080e7          	jalr	844(ra) # 80004b82 <pipeclose>
    8000483e:	b7cd                	j	80004820 <fileclose+0xa8>

0000000080004840 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004840:	715d                	addi	sp,sp,-80
    80004842:	e486                	sd	ra,72(sp)
    80004844:	e0a2                	sd	s0,64(sp)
    80004846:	fc26                	sd	s1,56(sp)
    80004848:	f84a                	sd	s2,48(sp)
    8000484a:	f44e                	sd	s3,40(sp)
    8000484c:	0880                	addi	s0,sp,80
    8000484e:	84aa                	mv	s1,a0
    80004850:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004852:	ffffd097          	auipc	ra,0xffffd
    80004856:	2e2080e7          	jalr	738(ra) # 80001b34 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000485a:	409c                	lw	a5,0(s1)
    8000485c:	37f9                	addiw	a5,a5,-2
    8000485e:	4705                	li	a4,1
    80004860:	04f76763          	bltu	a4,a5,800048ae <filestat+0x6e>
    80004864:	892a                	mv	s2,a0
    ilock(f->ip);
    80004866:	6c88                	ld	a0,24(s1)
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	082080e7          	jalr	130(ra) # 800038ea <ilock>
    stati(f->ip, &st);
    80004870:	fb840593          	addi	a1,s0,-72
    80004874:	6c88                	ld	a0,24(s1)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	2fe080e7          	jalr	766(ra) # 80003b74 <stati>
    iunlock(f->ip);
    8000487e:	6c88                	ld	a0,24(s1)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	12c080e7          	jalr	300(ra) # 800039ac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004888:	46e1                	li	a3,24
    8000488a:	fb840613          	addi	a2,s0,-72
    8000488e:	85ce                	mv	a1,s3
    80004890:	05093503          	ld	a0,80(s2)
    80004894:	ffffd097          	auipc	ra,0xffffd
    80004898:	f5c080e7          	jalr	-164(ra) # 800017f0 <copyout>
    8000489c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048a0:	60a6                	ld	ra,72(sp)
    800048a2:	6406                	ld	s0,64(sp)
    800048a4:	74e2                	ld	s1,56(sp)
    800048a6:	7942                	ld	s2,48(sp)
    800048a8:	79a2                	ld	s3,40(sp)
    800048aa:	6161                	addi	sp,sp,80
    800048ac:	8082                	ret
  return -1;
    800048ae:	557d                	li	a0,-1
    800048b0:	bfc5                	j	800048a0 <filestat+0x60>

00000000800048b2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048b2:	7179                	addi	sp,sp,-48
    800048b4:	f406                	sd	ra,40(sp)
    800048b6:	f022                	sd	s0,32(sp)
    800048b8:	ec26                	sd	s1,24(sp)
    800048ba:	e84a                	sd	s2,16(sp)
    800048bc:	e44e                	sd	s3,8(sp)
    800048be:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048c0:	00854783          	lbu	a5,8(a0)
    800048c4:	c3d5                	beqz	a5,80004968 <fileread+0xb6>
    800048c6:	84aa                	mv	s1,a0
    800048c8:	89ae                	mv	s3,a1
    800048ca:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048cc:	411c                	lw	a5,0(a0)
    800048ce:	4705                	li	a4,1
    800048d0:	04e78963          	beq	a5,a4,80004922 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d4:	470d                	li	a4,3
    800048d6:	04e78d63          	beq	a5,a4,80004930 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048da:	4709                	li	a4,2
    800048dc:	06e79e63          	bne	a5,a4,80004958 <fileread+0xa6>
    ilock(f->ip);
    800048e0:	6d08                	ld	a0,24(a0)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	008080e7          	jalr	8(ra) # 800038ea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048ea:	874a                	mv	a4,s2
    800048ec:	5094                	lw	a3,32(s1)
    800048ee:	864e                	mv	a2,s3
    800048f0:	4585                	li	a1,1
    800048f2:	6c88                	ld	a0,24(s1)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	2aa080e7          	jalr	682(ra) # 80003b9e <readi>
    800048fc:	892a                	mv	s2,a0
    800048fe:	00a05563          	blez	a0,80004908 <fileread+0x56>
      f->off += r;
    80004902:	509c                	lw	a5,32(s1)
    80004904:	9fa9                	addw	a5,a5,a0
    80004906:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004908:	6c88                	ld	a0,24(s1)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	0a2080e7          	jalr	162(ra) # 800039ac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004912:	854a                	mv	a0,s2
    80004914:	70a2                	ld	ra,40(sp)
    80004916:	7402                	ld	s0,32(sp)
    80004918:	64e2                	ld	s1,24(sp)
    8000491a:	6942                	ld	s2,16(sp)
    8000491c:	69a2                	ld	s3,8(sp)
    8000491e:	6145                	addi	sp,sp,48
    80004920:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004922:	6908                	ld	a0,16(a0)
    80004924:	00000097          	auipc	ra,0x0
    80004928:	3c6080e7          	jalr	966(ra) # 80004cea <piperead>
    8000492c:	892a                	mv	s2,a0
    8000492e:	b7d5                	j	80004912 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004930:	02451783          	lh	a5,36(a0)
    80004934:	03079693          	slli	a3,a5,0x30
    80004938:	92c1                	srli	a3,a3,0x30
    8000493a:	4725                	li	a4,9
    8000493c:	02d76863          	bltu	a4,a3,8000496c <fileread+0xba>
    80004940:	0792                	slli	a5,a5,0x4
    80004942:	0001d717          	auipc	a4,0x1d
    80004946:	af670713          	addi	a4,a4,-1290 # 80021438 <devsw>
    8000494a:	97ba                	add	a5,a5,a4
    8000494c:	639c                	ld	a5,0(a5)
    8000494e:	c38d                	beqz	a5,80004970 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004950:	4505                	li	a0,1
    80004952:	9782                	jalr	a5
    80004954:	892a                	mv	s2,a0
    80004956:	bf75                	j	80004912 <fileread+0x60>
    panic("fileread");
    80004958:	00004517          	auipc	a0,0x4
    8000495c:	d9050513          	addi	a0,a0,-624 # 800086e8 <syscalls+0x268>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	d66080e7          	jalr	-666(ra) # 800006c6 <panic>
    return -1;
    80004968:	597d                	li	s2,-1
    8000496a:	b765                	j	80004912 <fileread+0x60>
      return -1;
    8000496c:	597d                	li	s2,-1
    8000496e:	b755                	j	80004912 <fileread+0x60>
    80004970:	597d                	li	s2,-1
    80004972:	b745                	j	80004912 <fileread+0x60>

0000000080004974 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004974:	715d                	addi	sp,sp,-80
    80004976:	e486                	sd	ra,72(sp)
    80004978:	e0a2                	sd	s0,64(sp)
    8000497a:	fc26                	sd	s1,56(sp)
    8000497c:	f84a                	sd	s2,48(sp)
    8000497e:	f44e                	sd	s3,40(sp)
    80004980:	f052                	sd	s4,32(sp)
    80004982:	ec56                	sd	s5,24(sp)
    80004984:	e85a                	sd	s6,16(sp)
    80004986:	e45e                	sd	s7,8(sp)
    80004988:	e062                	sd	s8,0(sp)
    8000498a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000498c:	00954783          	lbu	a5,9(a0)
    80004990:	10078663          	beqz	a5,80004a9c <filewrite+0x128>
    80004994:	892a                	mv	s2,a0
    80004996:	8aae                	mv	s5,a1
    80004998:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000499a:	411c                	lw	a5,0(a0)
    8000499c:	4705                	li	a4,1
    8000499e:	02e78263          	beq	a5,a4,800049c2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a2:	470d                	li	a4,3
    800049a4:	02e78663          	beq	a5,a4,800049d0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049a8:	4709                	li	a4,2
    800049aa:	0ee79163          	bne	a5,a4,80004a8c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049ae:	0ac05d63          	blez	a2,80004a68 <filewrite+0xf4>
    int i = 0;
    800049b2:	4981                	li	s3,0
    800049b4:	6b05                	lui	s6,0x1
    800049b6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049ba:	6b85                	lui	s7,0x1
    800049bc:	c00b8b9b          	addiw	s7,s7,-1024
    800049c0:	a861                	j	80004a58 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049c2:	6908                	ld	a0,16(a0)
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	22e080e7          	jalr	558(ra) # 80004bf2 <pipewrite>
    800049cc:	8a2a                	mv	s4,a0
    800049ce:	a045                	j	80004a6e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049d0:	02451783          	lh	a5,36(a0)
    800049d4:	03079693          	slli	a3,a5,0x30
    800049d8:	92c1                	srli	a3,a3,0x30
    800049da:	4725                	li	a4,9
    800049dc:	0cd76263          	bltu	a4,a3,80004aa0 <filewrite+0x12c>
    800049e0:	0792                	slli	a5,a5,0x4
    800049e2:	0001d717          	auipc	a4,0x1d
    800049e6:	a5670713          	addi	a4,a4,-1450 # 80021438 <devsw>
    800049ea:	97ba                	add	a5,a5,a4
    800049ec:	679c                	ld	a5,8(a5)
    800049ee:	cbdd                	beqz	a5,80004aa4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049f0:	4505                	li	a0,1
    800049f2:	9782                	jalr	a5
    800049f4:	8a2a                	mv	s4,a0
    800049f6:	a8a5                	j	80004a6e <filewrite+0xfa>
    800049f8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049fc:	00000097          	auipc	ra,0x0
    80004a00:	8b0080e7          	jalr	-1872(ra) # 800042ac <begin_op>
      ilock(f->ip);
    80004a04:	01893503          	ld	a0,24(s2)
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	ee2080e7          	jalr	-286(ra) # 800038ea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a10:	8762                	mv	a4,s8
    80004a12:	02092683          	lw	a3,32(s2)
    80004a16:	01598633          	add	a2,s3,s5
    80004a1a:	4585                	li	a1,1
    80004a1c:	01893503          	ld	a0,24(s2)
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	276080e7          	jalr	630(ra) # 80003c96 <writei>
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	00a05763          	blez	a0,80004a38 <filewrite+0xc4>
        f->off += r;
    80004a2e:	02092783          	lw	a5,32(s2)
    80004a32:	9fa9                	addw	a5,a5,a0
    80004a34:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a38:	01893503          	ld	a0,24(s2)
    80004a3c:	fffff097          	auipc	ra,0xfffff
    80004a40:	f70080e7          	jalr	-144(ra) # 800039ac <iunlock>
      end_op();
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	8e8080e7          	jalr	-1816(ra) # 8000432c <end_op>

      if(r != n1){
    80004a4c:	009c1f63          	bne	s8,s1,80004a6a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a50:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a54:	0149db63          	bge	s3,s4,80004a6a <filewrite+0xf6>
      int n1 = n - i;
    80004a58:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a5c:	84be                	mv	s1,a5
    80004a5e:	2781                	sext.w	a5,a5
    80004a60:	f8fb5ce3          	bge	s6,a5,800049f8 <filewrite+0x84>
    80004a64:	84de                	mv	s1,s7
    80004a66:	bf49                	j	800049f8 <filewrite+0x84>
    int i = 0;
    80004a68:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a6a:	013a1f63          	bne	s4,s3,80004a88 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a6e:	8552                	mv	a0,s4
    80004a70:	60a6                	ld	ra,72(sp)
    80004a72:	6406                	ld	s0,64(sp)
    80004a74:	74e2                	ld	s1,56(sp)
    80004a76:	7942                	ld	s2,48(sp)
    80004a78:	79a2                	ld	s3,40(sp)
    80004a7a:	7a02                	ld	s4,32(sp)
    80004a7c:	6ae2                	ld	s5,24(sp)
    80004a7e:	6b42                	ld	s6,16(sp)
    80004a80:	6ba2                	ld	s7,8(sp)
    80004a82:	6c02                	ld	s8,0(sp)
    80004a84:	6161                	addi	sp,sp,80
    80004a86:	8082                	ret
    ret = (i == n ? n : -1);
    80004a88:	5a7d                	li	s4,-1
    80004a8a:	b7d5                	j	80004a6e <filewrite+0xfa>
    panic("filewrite");
    80004a8c:	00004517          	auipc	a0,0x4
    80004a90:	c6c50513          	addi	a0,a0,-916 # 800086f8 <syscalls+0x278>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	c32080e7          	jalr	-974(ra) # 800006c6 <panic>
    return -1;
    80004a9c:	5a7d                	li	s4,-1
    80004a9e:	bfc1                	j	80004a6e <filewrite+0xfa>
      return -1;
    80004aa0:	5a7d                	li	s4,-1
    80004aa2:	b7f1                	j	80004a6e <filewrite+0xfa>
    80004aa4:	5a7d                	li	s4,-1
    80004aa6:	b7e1                	j	80004a6e <filewrite+0xfa>

0000000080004aa8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aa8:	7179                	addi	sp,sp,-48
    80004aaa:	f406                	sd	ra,40(sp)
    80004aac:	f022                	sd	s0,32(sp)
    80004aae:	ec26                	sd	s1,24(sp)
    80004ab0:	e84a                	sd	s2,16(sp)
    80004ab2:	e44e                	sd	s3,8(sp)
    80004ab4:	e052                	sd	s4,0(sp)
    80004ab6:	1800                	addi	s0,sp,48
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004abc:	0005b023          	sd	zero,0(a1)
    80004ac0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ac4:	00000097          	auipc	ra,0x0
    80004ac8:	bf8080e7          	jalr	-1032(ra) # 800046bc <filealloc>
    80004acc:	e088                	sd	a0,0(s1)
    80004ace:	c551                	beqz	a0,80004b5a <pipealloc+0xb2>
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	bec080e7          	jalr	-1044(ra) # 800046bc <filealloc>
    80004ad8:	00aa3023          	sd	a0,0(s4)
    80004adc:	c92d                	beqz	a0,80004b4e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	190080e7          	jalr	400(ra) # 80000c6e <kalloc>
    80004ae6:	892a                	mv	s2,a0
    80004ae8:	c125                	beqz	a0,80004b48 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004aea:	4985                	li	s3,1
    80004aec:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004af0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004af4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004af8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004afc:	00004597          	auipc	a1,0x4
    80004b00:	c0c58593          	addi	a1,a1,-1012 # 80008708 <syscalls+0x288>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	1ca080e7          	jalr	458(ra) # 80000cce <initlock>
  (*f0)->type = FD_PIPE;
    80004b0c:	609c                	ld	a5,0(s1)
    80004b0e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b12:	609c                	ld	a5,0(s1)
    80004b14:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b18:	609c                	ld	a5,0(s1)
    80004b1a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b1e:	609c                	ld	a5,0(s1)
    80004b20:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b24:	000a3783          	ld	a5,0(s4)
    80004b28:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b2c:	000a3783          	ld	a5,0(s4)
    80004b30:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b34:	000a3783          	ld	a5,0(s4)
    80004b38:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b3c:	000a3783          	ld	a5,0(s4)
    80004b40:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b44:	4501                	li	a0,0
    80004b46:	a025                	j	80004b6e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b48:	6088                	ld	a0,0(s1)
    80004b4a:	e501                	bnez	a0,80004b52 <pipealloc+0xaa>
    80004b4c:	a039                	j	80004b5a <pipealloc+0xb2>
    80004b4e:	6088                	ld	a0,0(s1)
    80004b50:	c51d                	beqz	a0,80004b7e <pipealloc+0xd6>
    fileclose(*f0);
    80004b52:	00000097          	auipc	ra,0x0
    80004b56:	c26080e7          	jalr	-986(ra) # 80004778 <fileclose>
  if(*f1)
    80004b5a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b5e:	557d                	li	a0,-1
  if(*f1)
    80004b60:	c799                	beqz	a5,80004b6e <pipealloc+0xc6>
    fileclose(*f1);
    80004b62:	853e                	mv	a0,a5
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	c14080e7          	jalr	-1004(ra) # 80004778 <fileclose>
  return -1;
    80004b6c:	557d                	li	a0,-1
}
    80004b6e:	70a2                	ld	ra,40(sp)
    80004b70:	7402                	ld	s0,32(sp)
    80004b72:	64e2                	ld	s1,24(sp)
    80004b74:	6942                	ld	s2,16(sp)
    80004b76:	69a2                	ld	s3,8(sp)
    80004b78:	6a02                	ld	s4,0(sp)
    80004b7a:	6145                	addi	sp,sp,48
    80004b7c:	8082                	ret
  return -1;
    80004b7e:	557d                	li	a0,-1
    80004b80:	b7fd                	j	80004b6e <pipealloc+0xc6>

0000000080004b82 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b82:	1101                	addi	sp,sp,-32
    80004b84:	ec06                	sd	ra,24(sp)
    80004b86:	e822                	sd	s0,16(sp)
    80004b88:	e426                	sd	s1,8(sp)
    80004b8a:	e04a                	sd	s2,0(sp)
    80004b8c:	1000                	addi	s0,sp,32
    80004b8e:	84aa                	mv	s1,a0
    80004b90:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	1cc080e7          	jalr	460(ra) # 80000d5e <acquire>
  if(writable){
    80004b9a:	02090d63          	beqz	s2,80004bd4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b9e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ba2:	21848513          	addi	a0,s1,536
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	69a080e7          	jalr	1690(ra) # 80002240 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bae:	2204b783          	ld	a5,544(s1)
    80004bb2:	eb95                	bnez	a5,80004be6 <pipeclose+0x64>
    release(&pi->lock);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	25c080e7          	jalr	604(ra) # 80000e12 <release>
    kfree((char*)pi);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	fb2080e7          	jalr	-78(ra) # 80000b72 <kfree>
  } else
    release(&pi->lock);
}
    80004bc8:	60e2                	ld	ra,24(sp)
    80004bca:	6442                	ld	s0,16(sp)
    80004bcc:	64a2                	ld	s1,8(sp)
    80004bce:	6902                	ld	s2,0(sp)
    80004bd0:	6105                	addi	sp,sp,32
    80004bd2:	8082                	ret
    pi->readopen = 0;
    80004bd4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bd8:	21c48513          	addi	a0,s1,540
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	664080e7          	jalr	1636(ra) # 80002240 <wakeup>
    80004be4:	b7e9                	j	80004bae <pipeclose+0x2c>
    release(&pi->lock);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	22a080e7          	jalr	554(ra) # 80000e12 <release>
}
    80004bf0:	bfe1                	j	80004bc8 <pipeclose+0x46>

0000000080004bf2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bf2:	711d                	addi	sp,sp,-96
    80004bf4:	ec86                	sd	ra,88(sp)
    80004bf6:	e8a2                	sd	s0,80(sp)
    80004bf8:	e4a6                	sd	s1,72(sp)
    80004bfa:	e0ca                	sd	s2,64(sp)
    80004bfc:	fc4e                	sd	s3,56(sp)
    80004bfe:	f852                	sd	s4,48(sp)
    80004c00:	f456                	sd	s5,40(sp)
    80004c02:	f05a                	sd	s6,32(sp)
    80004c04:	ec5e                	sd	s7,24(sp)
    80004c06:	e862                	sd	s8,16(sp)
    80004c08:	1080                	addi	s0,sp,96
    80004c0a:	84aa                	mv	s1,a0
    80004c0c:	8aae                	mv	s5,a1
    80004c0e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	f24080e7          	jalr	-220(ra) # 80001b34 <myproc>
    80004c18:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c1a:	8526                	mv	a0,s1
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	142080e7          	jalr	322(ra) # 80000d5e <acquire>
  while(i < n){
    80004c24:	0b405663          	blez	s4,80004cd0 <pipewrite+0xde>
  int i = 0;
    80004c28:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c2a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c2c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c30:	21c48b93          	addi	s7,s1,540
    80004c34:	a089                	j	80004c76 <pipewrite+0x84>
      release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	1da080e7          	jalr	474(ra) # 80000e12 <release>
      return -1;
    80004c40:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c42:	854a                	mv	a0,s2
    80004c44:	60e6                	ld	ra,88(sp)
    80004c46:	6446                	ld	s0,80(sp)
    80004c48:	64a6                	ld	s1,72(sp)
    80004c4a:	6906                	ld	s2,64(sp)
    80004c4c:	79e2                	ld	s3,56(sp)
    80004c4e:	7a42                	ld	s4,48(sp)
    80004c50:	7aa2                	ld	s5,40(sp)
    80004c52:	7b02                	ld	s6,32(sp)
    80004c54:	6be2                	ld	s7,24(sp)
    80004c56:	6c42                	ld	s8,16(sp)
    80004c58:	6125                	addi	sp,sp,96
    80004c5a:	8082                	ret
      wakeup(&pi->nread);
    80004c5c:	8562                	mv	a0,s8
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	5e2080e7          	jalr	1506(ra) # 80002240 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c66:	85a6                	mv	a1,s1
    80004c68:	855e                	mv	a0,s7
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	572080e7          	jalr	1394(ra) # 800021dc <sleep>
  while(i < n){
    80004c72:	07495063          	bge	s2,s4,80004cd2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c76:	2204a783          	lw	a5,544(s1)
    80004c7a:	dfd5                	beqz	a5,80004c36 <pipewrite+0x44>
    80004c7c:	854e                	mv	a0,s3
    80004c7e:	ffffe097          	auipc	ra,0xffffe
    80004c82:	806080e7          	jalr	-2042(ra) # 80002484 <killed>
    80004c86:	f945                	bnez	a0,80004c36 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c88:	2184a783          	lw	a5,536(s1)
    80004c8c:	21c4a703          	lw	a4,540(s1)
    80004c90:	2007879b          	addiw	a5,a5,512
    80004c94:	fcf704e3          	beq	a4,a5,80004c5c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c98:	4685                	li	a3,1
    80004c9a:	01590633          	add	a2,s2,s5
    80004c9e:	faf40593          	addi	a1,s0,-81
    80004ca2:	0509b503          	ld	a0,80(s3)
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	bd6080e7          	jalr	-1066(ra) # 8000187c <copyin>
    80004cae:	03650263          	beq	a0,s6,80004cd2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cb2:	21c4a783          	lw	a5,540(s1)
    80004cb6:	0017871b          	addiw	a4,a5,1
    80004cba:	20e4ae23          	sw	a4,540(s1)
    80004cbe:	1ff7f793          	andi	a5,a5,511
    80004cc2:	97a6                	add	a5,a5,s1
    80004cc4:	faf44703          	lbu	a4,-81(s0)
    80004cc8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ccc:	2905                	addiw	s2,s2,1
    80004cce:	b755                	j	80004c72 <pipewrite+0x80>
  int i = 0;
    80004cd0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cd2:	21848513          	addi	a0,s1,536
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	56a080e7          	jalr	1386(ra) # 80002240 <wakeup>
  release(&pi->lock);
    80004cde:	8526                	mv	a0,s1
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	132080e7          	jalr	306(ra) # 80000e12 <release>
  return i;
    80004ce8:	bfa9                	j	80004c42 <pipewrite+0x50>

0000000080004cea <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cea:	715d                	addi	sp,sp,-80
    80004cec:	e486                	sd	ra,72(sp)
    80004cee:	e0a2                	sd	s0,64(sp)
    80004cf0:	fc26                	sd	s1,56(sp)
    80004cf2:	f84a                	sd	s2,48(sp)
    80004cf4:	f44e                	sd	s3,40(sp)
    80004cf6:	f052                	sd	s4,32(sp)
    80004cf8:	ec56                	sd	s5,24(sp)
    80004cfa:	e85a                	sd	s6,16(sp)
    80004cfc:	0880                	addi	s0,sp,80
    80004cfe:	84aa                	mv	s1,a0
    80004d00:	892e                	mv	s2,a1
    80004d02:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	e30080e7          	jalr	-464(ra) # 80001b34 <myproc>
    80004d0c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	04e080e7          	jalr	78(ra) # 80000d5e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d18:	2184a703          	lw	a4,536(s1)
    80004d1c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d20:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d24:	02f71763          	bne	a4,a5,80004d52 <piperead+0x68>
    80004d28:	2244a783          	lw	a5,548(s1)
    80004d2c:	c39d                	beqz	a5,80004d52 <piperead+0x68>
    if(killed(pr)){
    80004d2e:	8552                	mv	a0,s4
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	754080e7          	jalr	1876(ra) # 80002484 <killed>
    80004d38:	e941                	bnez	a0,80004dc8 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3a:	85a6                	mv	a1,s1
    80004d3c:	854e                	mv	a0,s3
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	49e080e7          	jalr	1182(ra) # 800021dc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d46:	2184a703          	lw	a4,536(s1)
    80004d4a:	21c4a783          	lw	a5,540(s1)
    80004d4e:	fcf70de3          	beq	a4,a5,80004d28 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d52:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d54:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d56:	05505363          	blez	s5,80004d9c <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d5a:	2184a783          	lw	a5,536(s1)
    80004d5e:	21c4a703          	lw	a4,540(s1)
    80004d62:	02f70d63          	beq	a4,a5,80004d9c <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d66:	0017871b          	addiw	a4,a5,1
    80004d6a:	20e4ac23          	sw	a4,536(s1)
    80004d6e:	1ff7f793          	andi	a5,a5,511
    80004d72:	97a6                	add	a5,a5,s1
    80004d74:	0187c783          	lbu	a5,24(a5)
    80004d78:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d7c:	4685                	li	a3,1
    80004d7e:	fbf40613          	addi	a2,s0,-65
    80004d82:	85ca                	mv	a1,s2
    80004d84:	050a3503          	ld	a0,80(s4)
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	a68080e7          	jalr	-1432(ra) # 800017f0 <copyout>
    80004d90:	01650663          	beq	a0,s6,80004d9c <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d94:	2985                	addiw	s3,s3,1
    80004d96:	0905                	addi	s2,s2,1
    80004d98:	fd3a91e3          	bne	s5,s3,80004d5a <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d9c:	21c48513          	addi	a0,s1,540
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	4a0080e7          	jalr	1184(ra) # 80002240 <wakeup>
  release(&pi->lock);
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	068080e7          	jalr	104(ra) # 80000e12 <release>
  return i;
}
    80004db2:	854e                	mv	a0,s3
    80004db4:	60a6                	ld	ra,72(sp)
    80004db6:	6406                	ld	s0,64(sp)
    80004db8:	74e2                	ld	s1,56(sp)
    80004dba:	7942                	ld	s2,48(sp)
    80004dbc:	79a2                	ld	s3,40(sp)
    80004dbe:	7a02                	ld	s4,32(sp)
    80004dc0:	6ae2                	ld	s5,24(sp)
    80004dc2:	6b42                	ld	s6,16(sp)
    80004dc4:	6161                	addi	sp,sp,80
    80004dc6:	8082                	ret
      release(&pi->lock);
    80004dc8:	8526                	mv	a0,s1
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	048080e7          	jalr	72(ra) # 80000e12 <release>
      return -1;
    80004dd2:	59fd                	li	s3,-1
    80004dd4:	bff9                	j	80004db2 <piperead+0xc8>

0000000080004dd6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dd6:	1141                	addi	sp,sp,-16
    80004dd8:	e422                	sd	s0,8(sp)
    80004dda:	0800                	addi	s0,sp,16
    80004ddc:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dde:	8905                	andi	a0,a0,1
    80004de0:	c111                	beqz	a0,80004de4 <flags2perm+0xe>
      perm = PTE_X;
    80004de2:	4521                	li	a0,8
    if(flags & 0x2)
    80004de4:	8b89                	andi	a5,a5,2
    80004de6:	c399                	beqz	a5,80004dec <flags2perm+0x16>
      perm |= PTE_W;
    80004de8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004dec:	6422                	ld	s0,8(sp)
    80004dee:	0141                	addi	sp,sp,16
    80004df0:	8082                	ret

0000000080004df2 <exec>:

int
exec(char *path, char **argv)
{
    80004df2:	de010113          	addi	sp,sp,-544
    80004df6:	20113c23          	sd	ra,536(sp)
    80004dfa:	20813823          	sd	s0,528(sp)
    80004dfe:	20913423          	sd	s1,520(sp)
    80004e02:	21213023          	sd	s2,512(sp)
    80004e06:	ffce                	sd	s3,504(sp)
    80004e08:	fbd2                	sd	s4,496(sp)
    80004e0a:	f7d6                	sd	s5,488(sp)
    80004e0c:	f3da                	sd	s6,480(sp)
    80004e0e:	efde                	sd	s7,472(sp)
    80004e10:	ebe2                	sd	s8,464(sp)
    80004e12:	e7e6                	sd	s9,456(sp)
    80004e14:	e3ea                	sd	s10,448(sp)
    80004e16:	ff6e                	sd	s11,440(sp)
    80004e18:	1400                	addi	s0,sp,544
    80004e1a:	892a                	mv	s2,a0
    80004e1c:	dea43423          	sd	a0,-536(s0)
    80004e20:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	d10080e7          	jalr	-752(ra) # 80001b34 <myproc>
    80004e2c:	84aa                	mv	s1,a0

  begin_op();
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	47e080e7          	jalr	1150(ra) # 800042ac <begin_op>

  if((ip = namei(path)) == 0){
    80004e36:	854a                	mv	a0,s2
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	258080e7          	jalr	600(ra) # 80004090 <namei>
    80004e40:	c93d                	beqz	a0,80004eb6 <exec+0xc4>
    80004e42:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	aa6080e7          	jalr	-1370(ra) # 800038ea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e4c:	04000713          	li	a4,64
    80004e50:	4681                	li	a3,0
    80004e52:	e5040613          	addi	a2,s0,-432
    80004e56:	4581                	li	a1,0
    80004e58:	8556                	mv	a0,s5
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	d44080e7          	jalr	-700(ra) # 80003b9e <readi>
    80004e62:	04000793          	li	a5,64
    80004e66:	00f51a63          	bne	a0,a5,80004e7a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e6a:	e5042703          	lw	a4,-432(s0)
    80004e6e:	464c47b7          	lui	a5,0x464c4
    80004e72:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e76:	04f70663          	beq	a4,a5,80004ec2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e7a:	8556                	mv	a0,s5
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	cd0080e7          	jalr	-816(ra) # 80003b4c <iunlockput>
    end_op();
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	4a8080e7          	jalr	1192(ra) # 8000432c <end_op>
  }
  return -1;
    80004e8c:	557d                	li	a0,-1
}
    80004e8e:	21813083          	ld	ra,536(sp)
    80004e92:	21013403          	ld	s0,528(sp)
    80004e96:	20813483          	ld	s1,520(sp)
    80004e9a:	20013903          	ld	s2,512(sp)
    80004e9e:	79fe                	ld	s3,504(sp)
    80004ea0:	7a5e                	ld	s4,496(sp)
    80004ea2:	7abe                	ld	s5,488(sp)
    80004ea4:	7b1e                	ld	s6,480(sp)
    80004ea6:	6bfe                	ld	s7,472(sp)
    80004ea8:	6c5e                	ld	s8,464(sp)
    80004eaa:	6cbe                	ld	s9,456(sp)
    80004eac:	6d1e                	ld	s10,448(sp)
    80004eae:	7dfa                	ld	s11,440(sp)
    80004eb0:	22010113          	addi	sp,sp,544
    80004eb4:	8082                	ret
    end_op();
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	476080e7          	jalr	1142(ra) # 8000432c <end_op>
    return -1;
    80004ebe:	557d                	li	a0,-1
    80004ec0:	b7f9                	j	80004e8e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ec2:	8526                	mv	a0,s1
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	d34080e7          	jalr	-716(ra) # 80001bf8 <proc_pagetable>
    80004ecc:	8b2a                	mv	s6,a0
    80004ece:	d555                	beqz	a0,80004e7a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed0:	e7042783          	lw	a5,-400(s0)
    80004ed4:	e8845703          	lhu	a4,-376(s0)
    80004ed8:	c735                	beqz	a4,80004f44 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eda:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004edc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ee0:	6a05                	lui	s4,0x1
    80004ee2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ee6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004eea:	6d85                	lui	s11,0x1
    80004eec:	7d7d                	lui	s10,0xfffff
    80004eee:	a481                	j	8000512e <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ef0:	00004517          	auipc	a0,0x4
    80004ef4:	82050513          	addi	a0,a0,-2016 # 80008710 <syscalls+0x290>
    80004ef8:	ffffb097          	auipc	ra,0xffffb
    80004efc:	7ce080e7          	jalr	1998(ra) # 800006c6 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f00:	874a                	mv	a4,s2
    80004f02:	009c86bb          	addw	a3,s9,s1
    80004f06:	4581                	li	a1,0
    80004f08:	8556                	mv	a0,s5
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	c94080e7          	jalr	-876(ra) # 80003b9e <readi>
    80004f12:	2501                	sext.w	a0,a0
    80004f14:	1aa91a63          	bne	s2,a0,800050c8 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f18:	009d84bb          	addw	s1,s11,s1
    80004f1c:	013d09bb          	addw	s3,s10,s3
    80004f20:	1f74f763          	bgeu	s1,s7,8000510e <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004f24:	02049593          	slli	a1,s1,0x20
    80004f28:	9181                	srli	a1,a1,0x20
    80004f2a:	95e2                	add	a1,a1,s8
    80004f2c:	855a                	mv	a0,s6
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	2b6080e7          	jalr	694(ra) # 800011e4 <walkaddr>
    80004f36:	862a                	mv	a2,a0
    if(pa == 0)
    80004f38:	dd45                	beqz	a0,80004ef0 <exec+0xfe>
      n = PGSIZE;
    80004f3a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f3c:	fd49f2e3          	bgeu	s3,s4,80004f00 <exec+0x10e>
      n = sz - i;
    80004f40:	894e                	mv	s2,s3
    80004f42:	bf7d                	j	80004f00 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f44:	4901                	li	s2,0
  iunlockput(ip);
    80004f46:	8556                	mv	a0,s5
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	c04080e7          	jalr	-1020(ra) # 80003b4c <iunlockput>
  end_op();
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	3dc080e7          	jalr	988(ra) # 8000432c <end_op>
  p = myproc();
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	bdc080e7          	jalr	-1060(ra) # 80001b34 <myproc>
    80004f60:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f62:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f66:	6785                	lui	a5,0x1
    80004f68:	17fd                	addi	a5,a5,-1
    80004f6a:	993e                	add	s2,s2,a5
    80004f6c:	77fd                	lui	a5,0xfffff
    80004f6e:	00f977b3          	and	a5,s2,a5
    80004f72:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f76:	4691                	li	a3,4
    80004f78:	6609                	lui	a2,0x2
    80004f7a:	963e                	add	a2,a2,a5
    80004f7c:	85be                	mv	a1,a5
    80004f7e:	855a                	mv	a0,s6
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	618080e7          	jalr	1560(ra) # 80001598 <uvmalloc>
    80004f88:	8c2a                	mv	s8,a0
  ip = 0;
    80004f8a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f8c:	12050e63          	beqz	a0,800050c8 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f90:	75f9                	lui	a1,0xffffe
    80004f92:	95aa                	add	a1,a1,a0
    80004f94:	855a                	mv	a0,s6
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	828080e7          	jalr	-2008(ra) # 800017be <uvmclear>
  stackbase = sp - PGSIZE;
    80004f9e:	7afd                	lui	s5,0xfffff
    80004fa0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fa2:	df043783          	ld	a5,-528(s0)
    80004fa6:	6388                	ld	a0,0(a5)
    80004fa8:	c925                	beqz	a0,80005018 <exec+0x226>
    80004faa:	e9040993          	addi	s3,s0,-368
    80004fae:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fb2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fb4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	020080e7          	jalr	32(ra) # 80000fd6 <strlen>
    80004fbe:	0015079b          	addiw	a5,a0,1
    80004fc2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fc6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fca:	13596663          	bltu	s2,s5,800050f6 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fce:	df043d83          	ld	s11,-528(s0)
    80004fd2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fd6:	8552                	mv	a0,s4
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	ffe080e7          	jalr	-2(ra) # 80000fd6 <strlen>
    80004fe0:	0015069b          	addiw	a3,a0,1
    80004fe4:	8652                	mv	a2,s4
    80004fe6:	85ca                	mv	a1,s2
    80004fe8:	855a                	mv	a0,s6
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	806080e7          	jalr	-2042(ra) # 800017f0 <copyout>
    80004ff2:	10054663          	bltz	a0,800050fe <exec+0x30c>
    ustack[argc] = sp;
    80004ff6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ffa:	0485                	addi	s1,s1,1
    80004ffc:	008d8793          	addi	a5,s11,8
    80005000:	def43823          	sd	a5,-528(s0)
    80005004:	008db503          	ld	a0,8(s11)
    80005008:	c911                	beqz	a0,8000501c <exec+0x22a>
    if(argc >= MAXARG)
    8000500a:	09a1                	addi	s3,s3,8
    8000500c:	fb3c95e3          	bne	s9,s3,80004fb6 <exec+0x1c4>
  sz = sz1;
    80005010:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005014:	4a81                	li	s5,0
    80005016:	a84d                	j	800050c8 <exec+0x2d6>
  sp = sz;
    80005018:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000501a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000501c:	00349793          	slli	a5,s1,0x3
    80005020:	f9040713          	addi	a4,s0,-112
    80005024:	97ba                	add	a5,a5,a4
    80005026:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc930>
  sp -= (argc+1) * sizeof(uint64);
    8000502a:	00148693          	addi	a3,s1,1
    8000502e:	068e                	slli	a3,a3,0x3
    80005030:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005034:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005038:	01597663          	bgeu	s2,s5,80005044 <exec+0x252>
  sz = sz1;
    8000503c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005040:	4a81                	li	s5,0
    80005042:	a059                	j	800050c8 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005044:	e9040613          	addi	a2,s0,-368
    80005048:	85ca                	mv	a1,s2
    8000504a:	855a                	mv	a0,s6
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	7a4080e7          	jalr	1956(ra) # 800017f0 <copyout>
    80005054:	0a054963          	bltz	a0,80005106 <exec+0x314>
  p->trapframe->a1 = sp;
    80005058:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000505c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005060:	de843783          	ld	a5,-536(s0)
    80005064:	0007c703          	lbu	a4,0(a5)
    80005068:	cf11                	beqz	a4,80005084 <exec+0x292>
    8000506a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000506c:	02f00693          	li	a3,47
    80005070:	a039                	j	8000507e <exec+0x28c>
      last = s+1;
    80005072:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005076:	0785                	addi	a5,a5,1
    80005078:	fff7c703          	lbu	a4,-1(a5)
    8000507c:	c701                	beqz	a4,80005084 <exec+0x292>
    if(*s == '/')
    8000507e:	fed71ce3          	bne	a4,a3,80005076 <exec+0x284>
    80005082:	bfc5                	j	80005072 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005084:	4641                	li	a2,16
    80005086:	de843583          	ld	a1,-536(s0)
    8000508a:	158b8513          	addi	a0,s7,344
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	f16080e7          	jalr	-234(ra) # 80000fa4 <safestrcpy>
  oldpagetable = p->pagetable;
    80005096:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000509a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000509e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050a2:	058bb783          	ld	a5,88(s7)
    800050a6:	e6843703          	ld	a4,-408(s0)
    800050aa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ac:	058bb783          	ld	a5,88(s7)
    800050b0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050b4:	85ea                	mv	a1,s10
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	bde080e7          	jalr	-1058(ra) # 80001c94 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050be:	0004851b          	sext.w	a0,s1
    800050c2:	b3f1                	j	80004e8e <exec+0x9c>
    800050c4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050c8:	df843583          	ld	a1,-520(s0)
    800050cc:	855a                	mv	a0,s6
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	bc6080e7          	jalr	-1082(ra) # 80001c94 <proc_freepagetable>
  if(ip){
    800050d6:	da0a92e3          	bnez	s5,80004e7a <exec+0x88>
  return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	bb4d                	j	80004e8e <exec+0x9c>
    800050de:	df243c23          	sd	s2,-520(s0)
    800050e2:	b7dd                	j	800050c8 <exec+0x2d6>
    800050e4:	df243c23          	sd	s2,-520(s0)
    800050e8:	b7c5                	j	800050c8 <exec+0x2d6>
    800050ea:	df243c23          	sd	s2,-520(s0)
    800050ee:	bfe9                	j	800050c8 <exec+0x2d6>
    800050f0:	df243c23          	sd	s2,-520(s0)
    800050f4:	bfd1                	j	800050c8 <exec+0x2d6>
  sz = sz1;
    800050f6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050fa:	4a81                	li	s5,0
    800050fc:	b7f1                	j	800050c8 <exec+0x2d6>
  sz = sz1;
    800050fe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005102:	4a81                	li	s5,0
    80005104:	b7d1                	j	800050c8 <exec+0x2d6>
  sz = sz1;
    80005106:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000510a:	4a81                	li	s5,0
    8000510c:	bf75                	j	800050c8 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000510e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005112:	e0843783          	ld	a5,-504(s0)
    80005116:	0017869b          	addiw	a3,a5,1
    8000511a:	e0d43423          	sd	a3,-504(s0)
    8000511e:	e0043783          	ld	a5,-512(s0)
    80005122:	0387879b          	addiw	a5,a5,56
    80005126:	e8845703          	lhu	a4,-376(s0)
    8000512a:	e0e6dee3          	bge	a3,a4,80004f46 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000512e:	2781                	sext.w	a5,a5
    80005130:	e0f43023          	sd	a5,-512(s0)
    80005134:	03800713          	li	a4,56
    80005138:	86be                	mv	a3,a5
    8000513a:	e1840613          	addi	a2,s0,-488
    8000513e:	4581                	li	a1,0
    80005140:	8556                	mv	a0,s5
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	a5c080e7          	jalr	-1444(ra) # 80003b9e <readi>
    8000514a:	03800793          	li	a5,56
    8000514e:	f6f51be3          	bne	a0,a5,800050c4 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005152:	e1842783          	lw	a5,-488(s0)
    80005156:	4705                	li	a4,1
    80005158:	fae79de3          	bne	a5,a4,80005112 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000515c:	e4043483          	ld	s1,-448(s0)
    80005160:	e3843783          	ld	a5,-456(s0)
    80005164:	f6f4ede3          	bltu	s1,a5,800050de <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005168:	e2843783          	ld	a5,-472(s0)
    8000516c:	94be                	add	s1,s1,a5
    8000516e:	f6f4ebe3          	bltu	s1,a5,800050e4 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005172:	de043703          	ld	a4,-544(s0)
    80005176:	8ff9                	and	a5,a5,a4
    80005178:	fbad                	bnez	a5,800050ea <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000517a:	e1c42503          	lw	a0,-484(s0)
    8000517e:	00000097          	auipc	ra,0x0
    80005182:	c58080e7          	jalr	-936(ra) # 80004dd6 <flags2perm>
    80005186:	86aa                	mv	a3,a0
    80005188:	8626                	mv	a2,s1
    8000518a:	85ca                	mv	a1,s2
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	40a080e7          	jalr	1034(ra) # 80001598 <uvmalloc>
    80005196:	dea43c23          	sd	a0,-520(s0)
    8000519a:	d939                	beqz	a0,800050f0 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000519c:	e2843c03          	ld	s8,-472(s0)
    800051a0:	e2042c83          	lw	s9,-480(s0)
    800051a4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051a8:	f60b83e3          	beqz	s7,8000510e <exec+0x31c>
    800051ac:	89de                	mv	s3,s7
    800051ae:	4481                	li	s1,0
    800051b0:	bb95                	j	80004f24 <exec+0x132>

00000000800051b2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051b2:	7179                	addi	sp,sp,-48
    800051b4:	f406                	sd	ra,40(sp)
    800051b6:	f022                	sd	s0,32(sp)
    800051b8:	ec26                	sd	s1,24(sp)
    800051ba:	e84a                	sd	s2,16(sp)
    800051bc:	1800                	addi	s0,sp,48
    800051be:	892e                	mv	s2,a1
    800051c0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051c2:	fdc40593          	addi	a1,s0,-36
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	b58080e7          	jalr	-1192(ra) # 80002d1e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ce:	fdc42703          	lw	a4,-36(s0)
    800051d2:	47bd                	li	a5,15
    800051d4:	02e7eb63          	bltu	a5,a4,8000520a <argfd+0x58>
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	95c080e7          	jalr	-1700(ra) # 80001b34 <myproc>
    800051e0:	fdc42703          	lw	a4,-36(s0)
    800051e4:	01a70793          	addi	a5,a4,26
    800051e8:	078e                	slli	a5,a5,0x3
    800051ea:	953e                	add	a0,a0,a5
    800051ec:	611c                	ld	a5,0(a0)
    800051ee:	c385                	beqz	a5,8000520e <argfd+0x5c>
    return -1;
  if(pfd)
    800051f0:	00090463          	beqz	s2,800051f8 <argfd+0x46>
    *pfd = fd;
    800051f4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051f8:	4501                	li	a0,0
  if(pf)
    800051fa:	c091                	beqz	s1,800051fe <argfd+0x4c>
    *pf = f;
    800051fc:	e09c                	sd	a5,0(s1)
}
    800051fe:	70a2                	ld	ra,40(sp)
    80005200:	7402                	ld	s0,32(sp)
    80005202:	64e2                	ld	s1,24(sp)
    80005204:	6942                	ld	s2,16(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret
    return -1;
    8000520a:	557d                	li	a0,-1
    8000520c:	bfcd                	j	800051fe <argfd+0x4c>
    8000520e:	557d                	li	a0,-1
    80005210:	b7fd                	j	800051fe <argfd+0x4c>

0000000080005212 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005212:	1101                	addi	sp,sp,-32
    80005214:	ec06                	sd	ra,24(sp)
    80005216:	e822                	sd	s0,16(sp)
    80005218:	e426                	sd	s1,8(sp)
    8000521a:	1000                	addi	s0,sp,32
    8000521c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000521e:	ffffd097          	auipc	ra,0xffffd
    80005222:	916080e7          	jalr	-1770(ra) # 80001b34 <myproc>
    80005226:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005228:	0d050793          	addi	a5,a0,208
    8000522c:	4501                	li	a0,0
    8000522e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005230:	6398                	ld	a4,0(a5)
    80005232:	cb19                	beqz	a4,80005248 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005234:	2505                	addiw	a0,a0,1
    80005236:	07a1                	addi	a5,a5,8
    80005238:	fed51ce3          	bne	a0,a3,80005230 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000523c:	557d                	li	a0,-1
}
    8000523e:	60e2                	ld	ra,24(sp)
    80005240:	6442                	ld	s0,16(sp)
    80005242:	64a2                	ld	s1,8(sp)
    80005244:	6105                	addi	sp,sp,32
    80005246:	8082                	ret
      p->ofile[fd] = f;
    80005248:	01a50793          	addi	a5,a0,26
    8000524c:	078e                	slli	a5,a5,0x3
    8000524e:	963e                	add	a2,a2,a5
    80005250:	e204                	sd	s1,0(a2)
      return fd;
    80005252:	b7f5                	j	8000523e <fdalloc+0x2c>

0000000080005254 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005254:	715d                	addi	sp,sp,-80
    80005256:	e486                	sd	ra,72(sp)
    80005258:	e0a2                	sd	s0,64(sp)
    8000525a:	fc26                	sd	s1,56(sp)
    8000525c:	f84a                	sd	s2,48(sp)
    8000525e:	f44e                	sd	s3,40(sp)
    80005260:	f052                	sd	s4,32(sp)
    80005262:	ec56                	sd	s5,24(sp)
    80005264:	e85a                	sd	s6,16(sp)
    80005266:	0880                	addi	s0,sp,80
    80005268:	8b2e                	mv	s6,a1
    8000526a:	89b2                	mv	s3,a2
    8000526c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000526e:	fb040593          	addi	a1,s0,-80
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	e3c080e7          	jalr	-452(ra) # 800040ae <nameiparent>
    8000527a:	84aa                	mv	s1,a0
    8000527c:	14050f63          	beqz	a0,800053da <create+0x186>
    return 0;

  ilock(dp);
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	66a080e7          	jalr	1642(ra) # 800038ea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005288:	4601                	li	a2,0
    8000528a:	fb040593          	addi	a1,s0,-80
    8000528e:	8526                	mv	a0,s1
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	b3e080e7          	jalr	-1218(ra) # 80003dce <dirlookup>
    80005298:	8aaa                	mv	s5,a0
    8000529a:	c931                	beqz	a0,800052ee <create+0x9a>
    iunlockput(dp);
    8000529c:	8526                	mv	a0,s1
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	8ae080e7          	jalr	-1874(ra) # 80003b4c <iunlockput>
    ilock(ip);
    800052a6:	8556                	mv	a0,s5
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	642080e7          	jalr	1602(ra) # 800038ea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052b0:	000b059b          	sext.w	a1,s6
    800052b4:	4789                	li	a5,2
    800052b6:	02f59563          	bne	a1,a5,800052e0 <create+0x8c>
    800052ba:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdca74>
    800052be:	37f9                	addiw	a5,a5,-2
    800052c0:	17c2                	slli	a5,a5,0x30
    800052c2:	93c1                	srli	a5,a5,0x30
    800052c4:	4705                	li	a4,1
    800052c6:	00f76d63          	bltu	a4,a5,800052e0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052ca:	8556                	mv	a0,s5
    800052cc:	60a6                	ld	ra,72(sp)
    800052ce:	6406                	ld	s0,64(sp)
    800052d0:	74e2                	ld	s1,56(sp)
    800052d2:	7942                	ld	s2,48(sp)
    800052d4:	79a2                	ld	s3,40(sp)
    800052d6:	7a02                	ld	s4,32(sp)
    800052d8:	6ae2                	ld	s5,24(sp)
    800052da:	6b42                	ld	s6,16(sp)
    800052dc:	6161                	addi	sp,sp,80
    800052de:	8082                	ret
    iunlockput(ip);
    800052e0:	8556                	mv	a0,s5
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	86a080e7          	jalr	-1942(ra) # 80003b4c <iunlockput>
    return 0;
    800052ea:	4a81                	li	s5,0
    800052ec:	bff9                	j	800052ca <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052ee:	85da                	mv	a1,s6
    800052f0:	4088                	lw	a0,0(s1)
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	45c080e7          	jalr	1116(ra) # 8000374e <ialloc>
    800052fa:	8a2a                	mv	s4,a0
    800052fc:	c539                	beqz	a0,8000534a <create+0xf6>
  ilock(ip);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	5ec080e7          	jalr	1516(ra) # 800038ea <ilock>
  ip->major = major;
    80005306:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000530a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000530e:	4905                	li	s2,1
    80005310:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005314:	8552                	mv	a0,s4
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	50a080e7          	jalr	1290(ra) # 80003820 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000531e:	000b059b          	sext.w	a1,s6
    80005322:	03258b63          	beq	a1,s2,80005358 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005326:	004a2603          	lw	a2,4(s4)
    8000532a:	fb040593          	addi	a1,s0,-80
    8000532e:	8526                	mv	a0,s1
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	cae080e7          	jalr	-850(ra) # 80003fde <dirlink>
    80005338:	06054f63          	bltz	a0,800053b6 <create+0x162>
  iunlockput(dp);
    8000533c:	8526                	mv	a0,s1
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	80e080e7          	jalr	-2034(ra) # 80003b4c <iunlockput>
  return ip;
    80005346:	8ad2                	mv	s5,s4
    80005348:	b749                	j	800052ca <create+0x76>
    iunlockput(dp);
    8000534a:	8526                	mv	a0,s1
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	800080e7          	jalr	-2048(ra) # 80003b4c <iunlockput>
    return 0;
    80005354:	8ad2                	mv	s5,s4
    80005356:	bf95                	j	800052ca <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005358:	004a2603          	lw	a2,4(s4)
    8000535c:	00003597          	auipc	a1,0x3
    80005360:	3d458593          	addi	a1,a1,980 # 80008730 <syscalls+0x2b0>
    80005364:	8552                	mv	a0,s4
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	c78080e7          	jalr	-904(ra) # 80003fde <dirlink>
    8000536e:	04054463          	bltz	a0,800053b6 <create+0x162>
    80005372:	40d0                	lw	a2,4(s1)
    80005374:	00003597          	auipc	a1,0x3
    80005378:	3c458593          	addi	a1,a1,964 # 80008738 <syscalls+0x2b8>
    8000537c:	8552                	mv	a0,s4
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	c60080e7          	jalr	-928(ra) # 80003fde <dirlink>
    80005386:	02054863          	bltz	a0,800053b6 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000538a:	004a2603          	lw	a2,4(s4)
    8000538e:	fb040593          	addi	a1,s0,-80
    80005392:	8526                	mv	a0,s1
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	c4a080e7          	jalr	-950(ra) # 80003fde <dirlink>
    8000539c:	00054d63          	bltz	a0,800053b6 <create+0x162>
    dp->nlink++;  // for ".."
    800053a0:	04a4d783          	lhu	a5,74(s1)
    800053a4:	2785                	addiw	a5,a5,1
    800053a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053aa:	8526                	mv	a0,s1
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	474080e7          	jalr	1140(ra) # 80003820 <iupdate>
    800053b4:	b761                	j	8000533c <create+0xe8>
  ip->nlink = 0;
    800053b6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053ba:	8552                	mv	a0,s4
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	464080e7          	jalr	1124(ra) # 80003820 <iupdate>
  iunlockput(ip);
    800053c4:	8552                	mv	a0,s4
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	786080e7          	jalr	1926(ra) # 80003b4c <iunlockput>
  iunlockput(dp);
    800053ce:	8526                	mv	a0,s1
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	77c080e7          	jalr	1916(ra) # 80003b4c <iunlockput>
  return 0;
    800053d8:	bdcd                	j	800052ca <create+0x76>
    return 0;
    800053da:	8aaa                	mv	s5,a0
    800053dc:	b5fd                	j	800052ca <create+0x76>

00000000800053de <sys_dup>:
{
    800053de:	7179                	addi	sp,sp,-48
    800053e0:	f406                	sd	ra,40(sp)
    800053e2:	f022                	sd	s0,32(sp)
    800053e4:	ec26                	sd	s1,24(sp)
    800053e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053e8:	fd840613          	addi	a2,s0,-40
    800053ec:	4581                	li	a1,0
    800053ee:	4501                	li	a0,0
    800053f0:	00000097          	auipc	ra,0x0
    800053f4:	dc2080e7          	jalr	-574(ra) # 800051b2 <argfd>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053fa:	02054363          	bltz	a0,80005420 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053fe:	fd843503          	ld	a0,-40(s0)
    80005402:	00000097          	auipc	ra,0x0
    80005406:	e10080e7          	jalr	-496(ra) # 80005212 <fdalloc>
    8000540a:	84aa                	mv	s1,a0
    return -1;
    8000540c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000540e:	00054963          	bltz	a0,80005420 <sys_dup+0x42>
  filedup(f);
    80005412:	fd843503          	ld	a0,-40(s0)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	310080e7          	jalr	784(ra) # 80004726 <filedup>
  return fd;
    8000541e:	87a6                	mv	a5,s1
}
    80005420:	853e                	mv	a0,a5
    80005422:	70a2                	ld	ra,40(sp)
    80005424:	7402                	ld	s0,32(sp)
    80005426:	64e2                	ld	s1,24(sp)
    80005428:	6145                	addi	sp,sp,48
    8000542a:	8082                	ret

000000008000542c <sys_read>:
{
    8000542c:	7179                	addi	sp,sp,-48
    8000542e:	f406                	sd	ra,40(sp)
    80005430:	f022                	sd	s0,32(sp)
    80005432:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005434:	fd840593          	addi	a1,s0,-40
    80005438:	4505                	li	a0,1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	904080e7          	jalr	-1788(ra) # 80002d3e <argaddr>
  argint(2, &n);
    80005442:	fe440593          	addi	a1,s0,-28
    80005446:	4509                	li	a0,2
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	8d6080e7          	jalr	-1834(ra) # 80002d1e <argint>
  if(argfd(0, 0, &f) < 0)
    80005450:	fe840613          	addi	a2,s0,-24
    80005454:	4581                	li	a1,0
    80005456:	4501                	li	a0,0
    80005458:	00000097          	auipc	ra,0x0
    8000545c:	d5a080e7          	jalr	-678(ra) # 800051b2 <argfd>
    80005460:	87aa                	mv	a5,a0
    return -1;
    80005462:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005464:	0007cc63          	bltz	a5,8000547c <sys_read+0x50>
  return fileread(f, p, n);
    80005468:	fe442603          	lw	a2,-28(s0)
    8000546c:	fd843583          	ld	a1,-40(s0)
    80005470:	fe843503          	ld	a0,-24(s0)
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	43e080e7          	jalr	1086(ra) # 800048b2 <fileread>
}
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	6145                	addi	sp,sp,48
    80005482:	8082                	ret

0000000080005484 <sys_write>:
{
    80005484:	7179                	addi	sp,sp,-48
    80005486:	f406                	sd	ra,40(sp)
    80005488:	f022                	sd	s0,32(sp)
    8000548a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000548c:	fd840593          	addi	a1,s0,-40
    80005490:	4505                	li	a0,1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	8ac080e7          	jalr	-1876(ra) # 80002d3e <argaddr>
  argint(2, &n);
    8000549a:	fe440593          	addi	a1,s0,-28
    8000549e:	4509                	li	a0,2
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	87e080e7          	jalr	-1922(ra) # 80002d1e <argint>
  if(argfd(0, 0, &f) < 0)
    800054a8:	fe840613          	addi	a2,s0,-24
    800054ac:	4581                	li	a1,0
    800054ae:	4501                	li	a0,0
    800054b0:	00000097          	auipc	ra,0x0
    800054b4:	d02080e7          	jalr	-766(ra) # 800051b2 <argfd>
    800054b8:	87aa                	mv	a5,a0
    return -1;
    800054ba:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054bc:	0007cc63          	bltz	a5,800054d4 <sys_write+0x50>
  return filewrite(f, p, n);
    800054c0:	fe442603          	lw	a2,-28(s0)
    800054c4:	fd843583          	ld	a1,-40(s0)
    800054c8:	fe843503          	ld	a0,-24(s0)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	4a8080e7          	jalr	1192(ra) # 80004974 <filewrite>
}
    800054d4:	70a2                	ld	ra,40(sp)
    800054d6:	7402                	ld	s0,32(sp)
    800054d8:	6145                	addi	sp,sp,48
    800054da:	8082                	ret

00000000800054dc <sys_close>:
{
    800054dc:	1101                	addi	sp,sp,-32
    800054de:	ec06                	sd	ra,24(sp)
    800054e0:	e822                	sd	s0,16(sp)
    800054e2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054e4:	fe040613          	addi	a2,s0,-32
    800054e8:	fec40593          	addi	a1,s0,-20
    800054ec:	4501                	li	a0,0
    800054ee:	00000097          	auipc	ra,0x0
    800054f2:	cc4080e7          	jalr	-828(ra) # 800051b2 <argfd>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054f8:	02054463          	bltz	a0,80005520 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054fc:	ffffc097          	auipc	ra,0xffffc
    80005500:	638080e7          	jalr	1592(ra) # 80001b34 <myproc>
    80005504:	fec42783          	lw	a5,-20(s0)
    80005508:	07e9                	addi	a5,a5,26
    8000550a:	078e                	slli	a5,a5,0x3
    8000550c:	97aa                	add	a5,a5,a0
    8000550e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005512:	fe043503          	ld	a0,-32(s0)
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	262080e7          	jalr	610(ra) # 80004778 <fileclose>
  return 0;
    8000551e:	4781                	li	a5,0
}
    80005520:	853e                	mv	a0,a5
    80005522:	60e2                	ld	ra,24(sp)
    80005524:	6442                	ld	s0,16(sp)
    80005526:	6105                	addi	sp,sp,32
    80005528:	8082                	ret

000000008000552a <sys_fstat>:
{
    8000552a:	1101                	addi	sp,sp,-32
    8000552c:	ec06                	sd	ra,24(sp)
    8000552e:	e822                	sd	s0,16(sp)
    80005530:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005532:	fe040593          	addi	a1,s0,-32
    80005536:	4505                	li	a0,1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	806080e7          	jalr	-2042(ra) # 80002d3e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005540:	fe840613          	addi	a2,s0,-24
    80005544:	4581                	li	a1,0
    80005546:	4501                	li	a0,0
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	c6a080e7          	jalr	-918(ra) # 800051b2 <argfd>
    80005550:	87aa                	mv	a5,a0
    return -1;
    80005552:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005554:	0007ca63          	bltz	a5,80005568 <sys_fstat+0x3e>
  return filestat(f, st);
    80005558:	fe043583          	ld	a1,-32(s0)
    8000555c:	fe843503          	ld	a0,-24(s0)
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	2e0080e7          	jalr	736(ra) # 80004840 <filestat>
}
    80005568:	60e2                	ld	ra,24(sp)
    8000556a:	6442                	ld	s0,16(sp)
    8000556c:	6105                	addi	sp,sp,32
    8000556e:	8082                	ret

0000000080005570 <sys_link>:
{
    80005570:	7169                	addi	sp,sp,-304
    80005572:	f606                	sd	ra,296(sp)
    80005574:	f222                	sd	s0,288(sp)
    80005576:	ee26                	sd	s1,280(sp)
    80005578:	ea4a                	sd	s2,272(sp)
    8000557a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557c:	08000613          	li	a2,128
    80005580:	ed040593          	addi	a1,s0,-304
    80005584:	4501                	li	a0,0
    80005586:	ffffd097          	auipc	ra,0xffffd
    8000558a:	7d8080e7          	jalr	2008(ra) # 80002d5e <argstr>
    return -1;
    8000558e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005590:	10054e63          	bltz	a0,800056ac <sys_link+0x13c>
    80005594:	08000613          	li	a2,128
    80005598:	f5040593          	addi	a1,s0,-176
    8000559c:	4505                	li	a0,1
    8000559e:	ffffd097          	auipc	ra,0xffffd
    800055a2:	7c0080e7          	jalr	1984(ra) # 80002d5e <argstr>
    return -1;
    800055a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a8:	10054263          	bltz	a0,800056ac <sys_link+0x13c>
  begin_op();
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	d00080e7          	jalr	-768(ra) # 800042ac <begin_op>
  if((ip = namei(old)) == 0){
    800055b4:	ed040513          	addi	a0,s0,-304
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	ad8080e7          	jalr	-1320(ra) # 80004090 <namei>
    800055c0:	84aa                	mv	s1,a0
    800055c2:	c551                	beqz	a0,8000564e <sys_link+0xde>
  ilock(ip);
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	326080e7          	jalr	806(ra) # 800038ea <ilock>
  if(ip->type == T_DIR){
    800055cc:	04449703          	lh	a4,68(s1)
    800055d0:	4785                	li	a5,1
    800055d2:	08f70463          	beq	a4,a5,8000565a <sys_link+0xea>
  ip->nlink++;
    800055d6:	04a4d783          	lhu	a5,74(s1)
    800055da:	2785                	addiw	a5,a5,1
    800055dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	23e080e7          	jalr	574(ra) # 80003820 <iupdate>
  iunlock(ip);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	3c0080e7          	jalr	960(ra) # 800039ac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055f4:	fd040593          	addi	a1,s0,-48
    800055f8:	f5040513          	addi	a0,s0,-176
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	ab2080e7          	jalr	-1358(ra) # 800040ae <nameiparent>
    80005604:	892a                	mv	s2,a0
    80005606:	c935                	beqz	a0,8000567a <sys_link+0x10a>
  ilock(dp);
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	2e2080e7          	jalr	738(ra) # 800038ea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005610:	00092703          	lw	a4,0(s2)
    80005614:	409c                	lw	a5,0(s1)
    80005616:	04f71d63          	bne	a4,a5,80005670 <sys_link+0x100>
    8000561a:	40d0                	lw	a2,4(s1)
    8000561c:	fd040593          	addi	a1,s0,-48
    80005620:	854a                	mv	a0,s2
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	9bc080e7          	jalr	-1604(ra) # 80003fde <dirlink>
    8000562a:	04054363          	bltz	a0,80005670 <sys_link+0x100>
  iunlockput(dp);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	51c080e7          	jalr	1308(ra) # 80003b4c <iunlockput>
  iput(ip);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	46a080e7          	jalr	1130(ra) # 80003aa4 <iput>
  end_op();
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	cea080e7          	jalr	-790(ra) # 8000432c <end_op>
  return 0;
    8000564a:	4781                	li	a5,0
    8000564c:	a085                	j	800056ac <sys_link+0x13c>
    end_op();
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	cde080e7          	jalr	-802(ra) # 8000432c <end_op>
    return -1;
    80005656:	57fd                	li	a5,-1
    80005658:	a891                	j	800056ac <sys_link+0x13c>
    iunlockput(ip);
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	4f0080e7          	jalr	1264(ra) # 80003b4c <iunlockput>
    end_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	cc8080e7          	jalr	-824(ra) # 8000432c <end_op>
    return -1;
    8000566c:	57fd                	li	a5,-1
    8000566e:	a83d                	j	800056ac <sys_link+0x13c>
    iunlockput(dp);
    80005670:	854a                	mv	a0,s2
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	4da080e7          	jalr	1242(ra) # 80003b4c <iunlockput>
  ilock(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	26e080e7          	jalr	622(ra) # 800038ea <ilock>
  ip->nlink--;
    80005684:	04a4d783          	lhu	a5,74(s1)
    80005688:	37fd                	addiw	a5,a5,-1
    8000568a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	190080e7          	jalr	400(ra) # 80003820 <iupdate>
  iunlockput(ip);
    80005698:	8526                	mv	a0,s1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	4b2080e7          	jalr	1202(ra) # 80003b4c <iunlockput>
  end_op();
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	c8a080e7          	jalr	-886(ra) # 8000432c <end_op>
  return -1;
    800056aa:	57fd                	li	a5,-1
}
    800056ac:	853e                	mv	a0,a5
    800056ae:	70b2                	ld	ra,296(sp)
    800056b0:	7412                	ld	s0,288(sp)
    800056b2:	64f2                	ld	s1,280(sp)
    800056b4:	6952                	ld	s2,272(sp)
    800056b6:	6155                	addi	sp,sp,304
    800056b8:	8082                	ret

00000000800056ba <sys_unlink>:
{
    800056ba:	7151                	addi	sp,sp,-240
    800056bc:	f586                	sd	ra,232(sp)
    800056be:	f1a2                	sd	s0,224(sp)
    800056c0:	eda6                	sd	s1,216(sp)
    800056c2:	e9ca                	sd	s2,208(sp)
    800056c4:	e5ce                	sd	s3,200(sp)
    800056c6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056c8:	08000613          	li	a2,128
    800056cc:	f3040593          	addi	a1,s0,-208
    800056d0:	4501                	li	a0,0
    800056d2:	ffffd097          	auipc	ra,0xffffd
    800056d6:	68c080e7          	jalr	1676(ra) # 80002d5e <argstr>
    800056da:	18054163          	bltz	a0,8000585c <sys_unlink+0x1a2>
  begin_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	bce080e7          	jalr	-1074(ra) # 800042ac <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056e6:	fb040593          	addi	a1,s0,-80
    800056ea:	f3040513          	addi	a0,s0,-208
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	9c0080e7          	jalr	-1600(ra) # 800040ae <nameiparent>
    800056f6:	84aa                	mv	s1,a0
    800056f8:	c979                	beqz	a0,800057ce <sys_unlink+0x114>
  ilock(dp);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	1f0080e7          	jalr	496(ra) # 800038ea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005702:	00003597          	auipc	a1,0x3
    80005706:	02e58593          	addi	a1,a1,46 # 80008730 <syscalls+0x2b0>
    8000570a:	fb040513          	addi	a0,s0,-80
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	6a6080e7          	jalr	1702(ra) # 80003db4 <namecmp>
    80005716:	14050a63          	beqz	a0,8000586a <sys_unlink+0x1b0>
    8000571a:	00003597          	auipc	a1,0x3
    8000571e:	01e58593          	addi	a1,a1,30 # 80008738 <syscalls+0x2b8>
    80005722:	fb040513          	addi	a0,s0,-80
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	68e080e7          	jalr	1678(ra) # 80003db4 <namecmp>
    8000572e:	12050e63          	beqz	a0,8000586a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005732:	f2c40613          	addi	a2,s0,-212
    80005736:	fb040593          	addi	a1,s0,-80
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	692080e7          	jalr	1682(ra) # 80003dce <dirlookup>
    80005744:	892a                	mv	s2,a0
    80005746:	12050263          	beqz	a0,8000586a <sys_unlink+0x1b0>
  ilock(ip);
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	1a0080e7          	jalr	416(ra) # 800038ea <ilock>
  if(ip->nlink < 1)
    80005752:	04a91783          	lh	a5,74(s2)
    80005756:	08f05263          	blez	a5,800057da <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000575a:	04491703          	lh	a4,68(s2)
    8000575e:	4785                	li	a5,1
    80005760:	08f70563          	beq	a4,a5,800057ea <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005764:	4641                	li	a2,16
    80005766:	4581                	li	a1,0
    80005768:	fc040513          	addi	a0,s0,-64
    8000576c:	ffffb097          	auipc	ra,0xffffb
    80005770:	6ee080e7          	jalr	1774(ra) # 80000e5a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005774:	4741                	li	a4,16
    80005776:	f2c42683          	lw	a3,-212(s0)
    8000577a:	fc040613          	addi	a2,s0,-64
    8000577e:	4581                	li	a1,0
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	514080e7          	jalr	1300(ra) # 80003c96 <writei>
    8000578a:	47c1                	li	a5,16
    8000578c:	0af51563          	bne	a0,a5,80005836 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005790:	04491703          	lh	a4,68(s2)
    80005794:	4785                	li	a5,1
    80005796:	0af70863          	beq	a4,a5,80005846 <sys_unlink+0x18c>
  iunlockput(dp);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	3b0080e7          	jalr	944(ra) # 80003b4c <iunlockput>
  ip->nlink--;
    800057a4:	04a95783          	lhu	a5,74(s2)
    800057a8:	37fd                	addiw	a5,a5,-1
    800057aa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057ae:	854a                	mv	a0,s2
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	070080e7          	jalr	112(ra) # 80003820 <iupdate>
  iunlockput(ip);
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	392080e7          	jalr	914(ra) # 80003b4c <iunlockput>
  end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	b6a080e7          	jalr	-1174(ra) # 8000432c <end_op>
  return 0;
    800057ca:	4501                	li	a0,0
    800057cc:	a84d                	j	8000587e <sys_unlink+0x1c4>
    end_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	b5e080e7          	jalr	-1186(ra) # 8000432c <end_op>
    return -1;
    800057d6:	557d                	li	a0,-1
    800057d8:	a05d                	j	8000587e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057da:	00003517          	auipc	a0,0x3
    800057de:	f6650513          	addi	a0,a0,-154 # 80008740 <syscalls+0x2c0>
    800057e2:	ffffb097          	auipc	ra,0xffffb
    800057e6:	ee4080e7          	jalr	-284(ra) # 800006c6 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ea:	04c92703          	lw	a4,76(s2)
    800057ee:	02000793          	li	a5,32
    800057f2:	f6e7f9e3          	bgeu	a5,a4,80005764 <sys_unlink+0xaa>
    800057f6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057fa:	4741                	li	a4,16
    800057fc:	86ce                	mv	a3,s3
    800057fe:	f1840613          	addi	a2,s0,-232
    80005802:	4581                	li	a1,0
    80005804:	854a                	mv	a0,s2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	398080e7          	jalr	920(ra) # 80003b9e <readi>
    8000580e:	47c1                	li	a5,16
    80005810:	00f51b63          	bne	a0,a5,80005826 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005814:	f1845783          	lhu	a5,-232(s0)
    80005818:	e7a1                	bnez	a5,80005860 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000581a:	29c1                	addiw	s3,s3,16
    8000581c:	04c92783          	lw	a5,76(s2)
    80005820:	fcf9ede3          	bltu	s3,a5,800057fa <sys_unlink+0x140>
    80005824:	b781                	j	80005764 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005826:	00003517          	auipc	a0,0x3
    8000582a:	f3250513          	addi	a0,a0,-206 # 80008758 <syscalls+0x2d8>
    8000582e:	ffffb097          	auipc	ra,0xffffb
    80005832:	e98080e7          	jalr	-360(ra) # 800006c6 <panic>
    panic("unlink: writei");
    80005836:	00003517          	auipc	a0,0x3
    8000583a:	f3a50513          	addi	a0,a0,-198 # 80008770 <syscalls+0x2f0>
    8000583e:	ffffb097          	auipc	ra,0xffffb
    80005842:	e88080e7          	jalr	-376(ra) # 800006c6 <panic>
    dp->nlink--;
    80005846:	04a4d783          	lhu	a5,74(s1)
    8000584a:	37fd                	addiw	a5,a5,-1
    8000584c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	fce080e7          	jalr	-50(ra) # 80003820 <iupdate>
    8000585a:	b781                	j	8000579a <sys_unlink+0xe0>
    return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	a005                	j	8000587e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005860:	854a                	mv	a0,s2
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	2ea080e7          	jalr	746(ra) # 80003b4c <iunlockput>
  iunlockput(dp);
    8000586a:	8526                	mv	a0,s1
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	2e0080e7          	jalr	736(ra) # 80003b4c <iunlockput>
  end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	ab8080e7          	jalr	-1352(ra) # 8000432c <end_op>
  return -1;
    8000587c:	557d                	li	a0,-1
}
    8000587e:	70ae                	ld	ra,232(sp)
    80005880:	740e                	ld	s0,224(sp)
    80005882:	64ee                	ld	s1,216(sp)
    80005884:	694e                	ld	s2,208(sp)
    80005886:	69ae                	ld	s3,200(sp)
    80005888:	616d                	addi	sp,sp,240
    8000588a:	8082                	ret

000000008000588c <sys_open>:

uint64
sys_open(void)
{
    8000588c:	7131                	addi	sp,sp,-192
    8000588e:	fd06                	sd	ra,184(sp)
    80005890:	f922                	sd	s0,176(sp)
    80005892:	f526                	sd	s1,168(sp)
    80005894:	f14a                	sd	s2,160(sp)
    80005896:	ed4e                	sd	s3,152(sp)
    80005898:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000589a:	f4c40593          	addi	a1,s0,-180
    8000589e:	4505                	li	a0,1
    800058a0:	ffffd097          	auipc	ra,0xffffd
    800058a4:	47e080e7          	jalr	1150(ra) # 80002d1e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058a8:	08000613          	li	a2,128
    800058ac:	f5040593          	addi	a1,s0,-176
    800058b0:	4501                	li	a0,0
    800058b2:	ffffd097          	auipc	ra,0xffffd
    800058b6:	4ac080e7          	jalr	1196(ra) # 80002d5e <argstr>
    800058ba:	87aa                	mv	a5,a0
    return -1;
    800058bc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058be:	0a07c963          	bltz	a5,80005970 <sys_open+0xe4>

  begin_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	9ea080e7          	jalr	-1558(ra) # 800042ac <begin_op>

  if(omode & O_CREATE){
    800058ca:	f4c42783          	lw	a5,-180(s0)
    800058ce:	2007f793          	andi	a5,a5,512
    800058d2:	cfc5                	beqz	a5,8000598a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058d4:	4681                	li	a3,0
    800058d6:	4601                	li	a2,0
    800058d8:	4589                	li	a1,2
    800058da:	f5040513          	addi	a0,s0,-176
    800058de:	00000097          	auipc	ra,0x0
    800058e2:	976080e7          	jalr	-1674(ra) # 80005254 <create>
    800058e6:	84aa                	mv	s1,a0
    if(ip == 0){
    800058e8:	c959                	beqz	a0,8000597e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058ea:	04449703          	lh	a4,68(s1)
    800058ee:	478d                	li	a5,3
    800058f0:	00f71763          	bne	a4,a5,800058fe <sys_open+0x72>
    800058f4:	0464d703          	lhu	a4,70(s1)
    800058f8:	47a5                	li	a5,9
    800058fa:	0ce7ed63          	bltu	a5,a4,800059d4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	dbe080e7          	jalr	-578(ra) # 800046bc <filealloc>
    80005906:	89aa                	mv	s3,a0
    80005908:	10050363          	beqz	a0,80005a0e <sys_open+0x182>
    8000590c:	00000097          	auipc	ra,0x0
    80005910:	906080e7          	jalr	-1786(ra) # 80005212 <fdalloc>
    80005914:	892a                	mv	s2,a0
    80005916:	0e054763          	bltz	a0,80005a04 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000591a:	04449703          	lh	a4,68(s1)
    8000591e:	478d                	li	a5,3
    80005920:	0cf70563          	beq	a4,a5,800059ea <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005924:	4789                	li	a5,2
    80005926:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000592a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000592e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005932:	f4c42783          	lw	a5,-180(s0)
    80005936:	0017c713          	xori	a4,a5,1
    8000593a:	8b05                	andi	a4,a4,1
    8000593c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005940:	0037f713          	andi	a4,a5,3
    80005944:	00e03733          	snez	a4,a4
    80005948:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000594c:	4007f793          	andi	a5,a5,1024
    80005950:	c791                	beqz	a5,8000595c <sys_open+0xd0>
    80005952:	04449703          	lh	a4,68(s1)
    80005956:	4789                	li	a5,2
    80005958:	0af70063          	beq	a4,a5,800059f8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	04e080e7          	jalr	78(ra) # 800039ac <iunlock>
  end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	9c6080e7          	jalr	-1594(ra) # 8000432c <end_op>

  return fd;
    8000596e:	854a                	mv	a0,s2
}
    80005970:	70ea                	ld	ra,184(sp)
    80005972:	744a                	ld	s0,176(sp)
    80005974:	74aa                	ld	s1,168(sp)
    80005976:	790a                	ld	s2,160(sp)
    80005978:	69ea                	ld	s3,152(sp)
    8000597a:	6129                	addi	sp,sp,192
    8000597c:	8082                	ret
      end_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	9ae080e7          	jalr	-1618(ra) # 8000432c <end_op>
      return -1;
    80005986:	557d                	li	a0,-1
    80005988:	b7e5                	j	80005970 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000598a:	f5040513          	addi	a0,s0,-176
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	702080e7          	jalr	1794(ra) # 80004090 <namei>
    80005996:	84aa                	mv	s1,a0
    80005998:	c905                	beqz	a0,800059c8 <sys_open+0x13c>
    ilock(ip);
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	f50080e7          	jalr	-176(ra) # 800038ea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059a2:	04449703          	lh	a4,68(s1)
    800059a6:	4785                	li	a5,1
    800059a8:	f4f711e3          	bne	a4,a5,800058ea <sys_open+0x5e>
    800059ac:	f4c42783          	lw	a5,-180(s0)
    800059b0:	d7b9                	beqz	a5,800058fe <sys_open+0x72>
      iunlockput(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	198080e7          	jalr	408(ra) # 80003b4c <iunlockput>
      end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	970080e7          	jalr	-1680(ra) # 8000432c <end_op>
      return -1;
    800059c4:	557d                	li	a0,-1
    800059c6:	b76d                	j	80005970 <sys_open+0xe4>
      end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	964080e7          	jalr	-1692(ra) # 8000432c <end_op>
      return -1;
    800059d0:	557d                	li	a0,-1
    800059d2:	bf79                	j	80005970 <sys_open+0xe4>
    iunlockput(ip);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	176080e7          	jalr	374(ra) # 80003b4c <iunlockput>
    end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	94e080e7          	jalr	-1714(ra) # 8000432c <end_op>
    return -1;
    800059e6:	557d                	li	a0,-1
    800059e8:	b761                	j	80005970 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059ea:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059ee:	04649783          	lh	a5,70(s1)
    800059f2:	02f99223          	sh	a5,36(s3)
    800059f6:	bf25                	j	8000592e <sys_open+0xa2>
    itrunc(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	ffe080e7          	jalr	-2(ra) # 800039f8 <itrunc>
    80005a02:	bfa9                	j	8000595c <sys_open+0xd0>
      fileclose(f);
    80005a04:	854e                	mv	a0,s3
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	d72080e7          	jalr	-654(ra) # 80004778 <fileclose>
    iunlockput(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	13c080e7          	jalr	316(ra) # 80003b4c <iunlockput>
    end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	914080e7          	jalr	-1772(ra) # 8000432c <end_op>
    return -1;
    80005a20:	557d                	li	a0,-1
    80005a22:	b7b9                	j	80005970 <sys_open+0xe4>

0000000080005a24 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a24:	7175                	addi	sp,sp,-144
    80005a26:	e506                	sd	ra,136(sp)
    80005a28:	e122                	sd	s0,128(sp)
    80005a2a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	880080e7          	jalr	-1920(ra) # 800042ac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a34:	08000613          	li	a2,128
    80005a38:	f7040593          	addi	a1,s0,-144
    80005a3c:	4501                	li	a0,0
    80005a3e:	ffffd097          	auipc	ra,0xffffd
    80005a42:	320080e7          	jalr	800(ra) # 80002d5e <argstr>
    80005a46:	02054963          	bltz	a0,80005a78 <sys_mkdir+0x54>
    80005a4a:	4681                	li	a3,0
    80005a4c:	4601                	li	a2,0
    80005a4e:	4585                	li	a1,1
    80005a50:	f7040513          	addi	a0,s0,-144
    80005a54:	00000097          	auipc	ra,0x0
    80005a58:	800080e7          	jalr	-2048(ra) # 80005254 <create>
    80005a5c:	cd11                	beqz	a0,80005a78 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	0ee080e7          	jalr	238(ra) # 80003b4c <iunlockput>
  end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	8c6080e7          	jalr	-1850(ra) # 8000432c <end_op>
  return 0;
    80005a6e:	4501                	li	a0,0
}
    80005a70:	60aa                	ld	ra,136(sp)
    80005a72:	640a                	ld	s0,128(sp)
    80005a74:	6149                	addi	sp,sp,144
    80005a76:	8082                	ret
    end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	8b4080e7          	jalr	-1868(ra) # 8000432c <end_op>
    return -1;
    80005a80:	557d                	li	a0,-1
    80005a82:	b7fd                	j	80005a70 <sys_mkdir+0x4c>

0000000080005a84 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a84:	7135                	addi	sp,sp,-160
    80005a86:	ed06                	sd	ra,152(sp)
    80005a88:	e922                	sd	s0,144(sp)
    80005a8a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	820080e7          	jalr	-2016(ra) # 800042ac <begin_op>
  argint(1, &major);
    80005a94:	f6c40593          	addi	a1,s0,-148
    80005a98:	4505                	li	a0,1
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	284080e7          	jalr	644(ra) # 80002d1e <argint>
  argint(2, &minor);
    80005aa2:	f6840593          	addi	a1,s0,-152
    80005aa6:	4509                	li	a0,2
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	276080e7          	jalr	630(ra) # 80002d1e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ab0:	08000613          	li	a2,128
    80005ab4:	f7040593          	addi	a1,s0,-144
    80005ab8:	4501                	li	a0,0
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	2a4080e7          	jalr	676(ra) # 80002d5e <argstr>
    80005ac2:	02054b63          	bltz	a0,80005af8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ac6:	f6841683          	lh	a3,-152(s0)
    80005aca:	f6c41603          	lh	a2,-148(s0)
    80005ace:	458d                	li	a1,3
    80005ad0:	f7040513          	addi	a0,s0,-144
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	780080e7          	jalr	1920(ra) # 80005254 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005adc:	cd11                	beqz	a0,80005af8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	06e080e7          	jalr	110(ra) # 80003b4c <iunlockput>
  end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	846080e7          	jalr	-1978(ra) # 8000432c <end_op>
  return 0;
    80005aee:	4501                	li	a0,0
}
    80005af0:	60ea                	ld	ra,152(sp)
    80005af2:	644a                	ld	s0,144(sp)
    80005af4:	610d                	addi	sp,sp,160
    80005af6:	8082                	ret
    end_op();
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	834080e7          	jalr	-1996(ra) # 8000432c <end_op>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	b7fd                	j	80005af0 <sys_mknod+0x6c>

0000000080005b04 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b04:	7135                	addi	sp,sp,-160
    80005b06:	ed06                	sd	ra,152(sp)
    80005b08:	e922                	sd	s0,144(sp)
    80005b0a:	e526                	sd	s1,136(sp)
    80005b0c:	e14a                	sd	s2,128(sp)
    80005b0e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b10:	ffffc097          	auipc	ra,0xffffc
    80005b14:	024080e7          	jalr	36(ra) # 80001b34 <myproc>
    80005b18:	892a                	mv	s2,a0
  
  begin_op();
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	792080e7          	jalr	1938(ra) # 800042ac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b22:	08000613          	li	a2,128
    80005b26:	f6040593          	addi	a1,s0,-160
    80005b2a:	4501                	li	a0,0
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	232080e7          	jalr	562(ra) # 80002d5e <argstr>
    80005b34:	04054b63          	bltz	a0,80005b8a <sys_chdir+0x86>
    80005b38:	f6040513          	addi	a0,s0,-160
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	554080e7          	jalr	1364(ra) # 80004090 <namei>
    80005b44:	84aa                	mv	s1,a0
    80005b46:	c131                	beqz	a0,80005b8a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	da2080e7          	jalr	-606(ra) # 800038ea <ilock>
  if(ip->type != T_DIR){
    80005b50:	04449703          	lh	a4,68(s1)
    80005b54:	4785                	li	a5,1
    80005b56:	04f71063          	bne	a4,a5,80005b96 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	e50080e7          	jalr	-432(ra) # 800039ac <iunlock>
  iput(p->cwd);
    80005b64:	15093503          	ld	a0,336(s2)
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	f3c080e7          	jalr	-196(ra) # 80003aa4 <iput>
  end_op();
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	7bc080e7          	jalr	1980(ra) # 8000432c <end_op>
  p->cwd = ip;
    80005b78:	14993823          	sd	s1,336(s2)
  return 0;
    80005b7c:	4501                	li	a0,0
}
    80005b7e:	60ea                	ld	ra,152(sp)
    80005b80:	644a                	ld	s0,144(sp)
    80005b82:	64aa                	ld	s1,136(sp)
    80005b84:	690a                	ld	s2,128(sp)
    80005b86:	610d                	addi	sp,sp,160
    80005b88:	8082                	ret
    end_op();
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	7a2080e7          	jalr	1954(ra) # 8000432c <end_op>
    return -1;
    80005b92:	557d                	li	a0,-1
    80005b94:	b7ed                	j	80005b7e <sys_chdir+0x7a>
    iunlockput(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	fb4080e7          	jalr	-76(ra) # 80003b4c <iunlockput>
    end_op();
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	78c080e7          	jalr	1932(ra) # 8000432c <end_op>
    return -1;
    80005ba8:	557d                	li	a0,-1
    80005baa:	bfd1                	j	80005b7e <sys_chdir+0x7a>

0000000080005bac <sys_exec>:

uint64
sys_exec(void)
{
    80005bac:	7145                	addi	sp,sp,-464
    80005bae:	e786                	sd	ra,456(sp)
    80005bb0:	e3a2                	sd	s0,448(sp)
    80005bb2:	ff26                	sd	s1,440(sp)
    80005bb4:	fb4a                	sd	s2,432(sp)
    80005bb6:	f74e                	sd	s3,424(sp)
    80005bb8:	f352                	sd	s4,416(sp)
    80005bba:	ef56                	sd	s5,408(sp)
    80005bbc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005bbe:	e3840593          	addi	a1,s0,-456
    80005bc2:	4505                	li	a0,1
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	17a080e7          	jalr	378(ra) # 80002d3e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bcc:	08000613          	li	a2,128
    80005bd0:	f4040593          	addi	a1,s0,-192
    80005bd4:	4501                	li	a0,0
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	188080e7          	jalr	392(ra) # 80002d5e <argstr>
    80005bde:	87aa                	mv	a5,a0
    return -1;
    80005be0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005be2:	0c07c263          	bltz	a5,80005ca6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005be6:	10000613          	li	a2,256
    80005bea:	4581                	li	a1,0
    80005bec:	e4040513          	addi	a0,s0,-448
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	26a080e7          	jalr	618(ra) # 80000e5a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bf8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bfc:	89a6                	mv	s3,s1
    80005bfe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c00:	02000a13          	li	s4,32
    80005c04:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c08:	00391793          	slli	a5,s2,0x3
    80005c0c:	e3040593          	addi	a1,s0,-464
    80005c10:	e3843503          	ld	a0,-456(s0)
    80005c14:	953e                	add	a0,a0,a5
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	06a080e7          	jalr	106(ra) # 80002c80 <fetchaddr>
    80005c1e:	02054a63          	bltz	a0,80005c52 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c22:	e3043783          	ld	a5,-464(s0)
    80005c26:	c3b9                	beqz	a5,80005c6c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c28:	ffffb097          	auipc	ra,0xffffb
    80005c2c:	046080e7          	jalr	70(ra) # 80000c6e <kalloc>
    80005c30:	85aa                	mv	a1,a0
    80005c32:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c36:	cd11                	beqz	a0,80005c52 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c38:	6605                	lui	a2,0x1
    80005c3a:	e3043503          	ld	a0,-464(s0)
    80005c3e:	ffffd097          	auipc	ra,0xffffd
    80005c42:	094080e7          	jalr	148(ra) # 80002cd2 <fetchstr>
    80005c46:	00054663          	bltz	a0,80005c52 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c4a:	0905                	addi	s2,s2,1
    80005c4c:	09a1                	addi	s3,s3,8
    80005c4e:	fb491be3          	bne	s2,s4,80005c04 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c52:	10048913          	addi	s2,s1,256
    80005c56:	6088                	ld	a0,0(s1)
    80005c58:	c531                	beqz	a0,80005ca4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	f18080e7          	jalr	-232(ra) # 80000b72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c62:	04a1                	addi	s1,s1,8
    80005c64:	ff2499e3          	bne	s1,s2,80005c56 <sys_exec+0xaa>
  return -1;
    80005c68:	557d                	li	a0,-1
    80005c6a:	a835                	j	80005ca6 <sys_exec+0xfa>
      argv[i] = 0;
    80005c6c:	0a8e                	slli	s5,s5,0x3
    80005c6e:	fc040793          	addi	a5,s0,-64
    80005c72:	9abe                	add	s5,s5,a5
    80005c74:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c78:	e4040593          	addi	a1,s0,-448
    80005c7c:	f4040513          	addi	a0,s0,-192
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	172080e7          	jalr	370(ra) # 80004df2 <exec>
    80005c88:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8a:	10048993          	addi	s3,s1,256
    80005c8e:	6088                	ld	a0,0(s1)
    80005c90:	c901                	beqz	a0,80005ca0 <sys_exec+0xf4>
    kfree(argv[i]);
    80005c92:	ffffb097          	auipc	ra,0xffffb
    80005c96:	ee0080e7          	jalr	-288(ra) # 80000b72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9a:	04a1                	addi	s1,s1,8
    80005c9c:	ff3499e3          	bne	s1,s3,80005c8e <sys_exec+0xe2>
  return ret;
    80005ca0:	854a                	mv	a0,s2
    80005ca2:	a011                	j	80005ca6 <sys_exec+0xfa>
  return -1;
    80005ca4:	557d                	li	a0,-1
}
    80005ca6:	60be                	ld	ra,456(sp)
    80005ca8:	641e                	ld	s0,448(sp)
    80005caa:	74fa                	ld	s1,440(sp)
    80005cac:	795a                	ld	s2,432(sp)
    80005cae:	79ba                	ld	s3,424(sp)
    80005cb0:	7a1a                	ld	s4,416(sp)
    80005cb2:	6afa                	ld	s5,408(sp)
    80005cb4:	6179                	addi	sp,sp,464
    80005cb6:	8082                	ret

0000000080005cb8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cb8:	7139                	addi	sp,sp,-64
    80005cba:	fc06                	sd	ra,56(sp)
    80005cbc:	f822                	sd	s0,48(sp)
    80005cbe:	f426                	sd	s1,40(sp)
    80005cc0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cc2:	ffffc097          	auipc	ra,0xffffc
    80005cc6:	e72080e7          	jalr	-398(ra) # 80001b34 <myproc>
    80005cca:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ccc:	fd840593          	addi	a1,s0,-40
    80005cd0:	4501                	li	a0,0
    80005cd2:	ffffd097          	auipc	ra,0xffffd
    80005cd6:	06c080e7          	jalr	108(ra) # 80002d3e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005cda:	fc840593          	addi	a1,s0,-56
    80005cde:	fd040513          	addi	a0,s0,-48
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	dc6080e7          	jalr	-570(ra) # 80004aa8 <pipealloc>
    return -1;
    80005cea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cec:	0c054463          	bltz	a0,80005db4 <sys_pipe+0xfc>
  fd0 = -1;
    80005cf0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cf4:	fd043503          	ld	a0,-48(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	51a080e7          	jalr	1306(ra) # 80005212 <fdalloc>
    80005d00:	fca42223          	sw	a0,-60(s0)
    80005d04:	08054b63          	bltz	a0,80005d9a <sys_pipe+0xe2>
    80005d08:	fc843503          	ld	a0,-56(s0)
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	506080e7          	jalr	1286(ra) # 80005212 <fdalloc>
    80005d14:	fca42023          	sw	a0,-64(s0)
    80005d18:	06054863          	bltz	a0,80005d88 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d1c:	4691                	li	a3,4
    80005d1e:	fc440613          	addi	a2,s0,-60
    80005d22:	fd843583          	ld	a1,-40(s0)
    80005d26:	68a8                	ld	a0,80(s1)
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	ac8080e7          	jalr	-1336(ra) # 800017f0 <copyout>
    80005d30:	02054063          	bltz	a0,80005d50 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d34:	4691                	li	a3,4
    80005d36:	fc040613          	addi	a2,s0,-64
    80005d3a:	fd843583          	ld	a1,-40(s0)
    80005d3e:	0591                	addi	a1,a1,4
    80005d40:	68a8                	ld	a0,80(s1)
    80005d42:	ffffc097          	auipc	ra,0xffffc
    80005d46:	aae080e7          	jalr	-1362(ra) # 800017f0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d4a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d4c:	06055463          	bgez	a0,80005db4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d50:	fc442783          	lw	a5,-60(s0)
    80005d54:	07e9                	addi	a5,a5,26
    80005d56:	078e                	slli	a5,a5,0x3
    80005d58:	97a6                	add	a5,a5,s1
    80005d5a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d5e:	fc042503          	lw	a0,-64(s0)
    80005d62:	0569                	addi	a0,a0,26
    80005d64:	050e                	slli	a0,a0,0x3
    80005d66:	94aa                	add	s1,s1,a0
    80005d68:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d6c:	fd043503          	ld	a0,-48(s0)
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	a08080e7          	jalr	-1528(ra) # 80004778 <fileclose>
    fileclose(wf);
    80005d78:	fc843503          	ld	a0,-56(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	9fc080e7          	jalr	-1540(ra) # 80004778 <fileclose>
    return -1;
    80005d84:	57fd                	li	a5,-1
    80005d86:	a03d                	j	80005db4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d88:	fc442783          	lw	a5,-60(s0)
    80005d8c:	0007c763          	bltz	a5,80005d9a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d90:	07e9                	addi	a5,a5,26
    80005d92:	078e                	slli	a5,a5,0x3
    80005d94:	94be                	add	s1,s1,a5
    80005d96:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d9a:	fd043503          	ld	a0,-48(s0)
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	9da080e7          	jalr	-1574(ra) # 80004778 <fileclose>
    fileclose(wf);
    80005da6:	fc843503          	ld	a0,-56(s0)
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	9ce080e7          	jalr	-1586(ra) # 80004778 <fileclose>
    return -1;
    80005db2:	57fd                	li	a5,-1
}
    80005db4:	853e                	mv	a0,a5
    80005db6:	70e2                	ld	ra,56(sp)
    80005db8:	7442                	ld	s0,48(sp)
    80005dba:	74a2                	ld	s1,40(sp)
    80005dbc:	6121                	addi	sp,sp,64
    80005dbe:	8082                	ret

0000000080005dc0 <kernelvec>:
    80005dc0:	7111                	addi	sp,sp,-256
    80005dc2:	e006                	sd	ra,0(sp)
    80005dc4:	e40a                	sd	sp,8(sp)
    80005dc6:	e80e                	sd	gp,16(sp)
    80005dc8:	ec12                	sd	tp,24(sp)
    80005dca:	f016                	sd	t0,32(sp)
    80005dcc:	f41a                	sd	t1,40(sp)
    80005dce:	f81e                	sd	t2,48(sp)
    80005dd0:	fc22                	sd	s0,56(sp)
    80005dd2:	e0a6                	sd	s1,64(sp)
    80005dd4:	e4aa                	sd	a0,72(sp)
    80005dd6:	e8ae                	sd	a1,80(sp)
    80005dd8:	ecb2                	sd	a2,88(sp)
    80005dda:	f0b6                	sd	a3,96(sp)
    80005ddc:	f4ba                	sd	a4,104(sp)
    80005dde:	f8be                	sd	a5,112(sp)
    80005de0:	fcc2                	sd	a6,120(sp)
    80005de2:	e146                	sd	a7,128(sp)
    80005de4:	e54a                	sd	s2,136(sp)
    80005de6:	e94e                	sd	s3,144(sp)
    80005de8:	ed52                	sd	s4,152(sp)
    80005dea:	f156                	sd	s5,160(sp)
    80005dec:	f55a                	sd	s6,168(sp)
    80005dee:	f95e                	sd	s7,176(sp)
    80005df0:	fd62                	sd	s8,184(sp)
    80005df2:	e1e6                	sd	s9,192(sp)
    80005df4:	e5ea                	sd	s10,200(sp)
    80005df6:	e9ee                	sd	s11,208(sp)
    80005df8:	edf2                	sd	t3,216(sp)
    80005dfa:	f1f6                	sd	t4,224(sp)
    80005dfc:	f5fa                	sd	t5,232(sp)
    80005dfe:	f9fe                	sd	t6,240(sp)
    80005e00:	d4dfc0ef          	jal	ra,80002b4c <kerneltrap>
    80005e04:	6082                	ld	ra,0(sp)
    80005e06:	6122                	ld	sp,8(sp)
    80005e08:	61c2                	ld	gp,16(sp)
    80005e0a:	7282                	ld	t0,32(sp)
    80005e0c:	7322                	ld	t1,40(sp)
    80005e0e:	73c2                	ld	t2,48(sp)
    80005e10:	7462                	ld	s0,56(sp)
    80005e12:	6486                	ld	s1,64(sp)
    80005e14:	6526                	ld	a0,72(sp)
    80005e16:	65c6                	ld	a1,80(sp)
    80005e18:	6666                	ld	a2,88(sp)
    80005e1a:	7686                	ld	a3,96(sp)
    80005e1c:	7726                	ld	a4,104(sp)
    80005e1e:	77c6                	ld	a5,112(sp)
    80005e20:	7866                	ld	a6,120(sp)
    80005e22:	688a                	ld	a7,128(sp)
    80005e24:	692a                	ld	s2,136(sp)
    80005e26:	69ca                	ld	s3,144(sp)
    80005e28:	6a6a                	ld	s4,152(sp)
    80005e2a:	7a8a                	ld	s5,160(sp)
    80005e2c:	7b2a                	ld	s6,168(sp)
    80005e2e:	7bca                	ld	s7,176(sp)
    80005e30:	7c6a                	ld	s8,184(sp)
    80005e32:	6c8e                	ld	s9,192(sp)
    80005e34:	6d2e                	ld	s10,200(sp)
    80005e36:	6dce                	ld	s11,208(sp)
    80005e38:	6e6e                	ld	t3,216(sp)
    80005e3a:	7e8e                	ld	t4,224(sp)
    80005e3c:	7f2e                	ld	t5,232(sp)
    80005e3e:	7fce                	ld	t6,240(sp)
    80005e40:	6111                	addi	sp,sp,256
    80005e42:	10200073          	sret
    80005e46:	00000013          	nop
    80005e4a:	00000013          	nop
    80005e4e:	0001                	nop

0000000080005e50 <timervec>:
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	e10c                	sd	a1,0(a0)
    80005e56:	e510                	sd	a2,8(a0)
    80005e58:	e914                	sd	a3,16(a0)
    80005e5a:	6d0c                	ld	a1,24(a0)
    80005e5c:	7110                	ld	a2,32(a0)
    80005e5e:	6194                	ld	a3,0(a1)
    80005e60:	96b2                	add	a3,a3,a2
    80005e62:	e194                	sd	a3,0(a1)
    80005e64:	4589                	li	a1,2
    80005e66:	14459073          	csrw	sip,a1
    80005e6a:	6914                	ld	a3,16(a0)
    80005e6c:	6510                	ld	a2,8(a0)
    80005e6e:	610c                	ld	a1,0(a0)
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	30200073          	mret
	...

0000000080005e7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e7a:	1141                	addi	sp,sp,-16
    80005e7c:	e422                	sd	s0,8(sp)
    80005e7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e80:	0c0007b7          	lui	a5,0xc000
    80005e84:	4705                	li	a4,1
    80005e86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e88:	c3d8                	sw	a4,4(a5)
}
    80005e8a:	6422                	ld	s0,8(sp)
    80005e8c:	0141                	addi	sp,sp,16
    80005e8e:	8082                	ret

0000000080005e90 <plicinithart>:

void
plicinithart(void)
{
    80005e90:	1141                	addi	sp,sp,-16
    80005e92:	e406                	sd	ra,8(sp)
    80005e94:	e022                	sd	s0,0(sp)
    80005e96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	c70080e7          	jalr	-912(ra) # 80001b08 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ea0:	0085171b          	slliw	a4,a0,0x8
    80005ea4:	0c0027b7          	lui	a5,0xc002
    80005ea8:	97ba                	add	a5,a5,a4
    80005eaa:	40200713          	li	a4,1026
    80005eae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005eb2:	00d5151b          	slliw	a0,a0,0xd
    80005eb6:	0c2017b7          	lui	a5,0xc201
    80005eba:	953e                	add	a0,a0,a5
    80005ebc:	00052023          	sw	zero,0(a0)
}
    80005ec0:	60a2                	ld	ra,8(sp)
    80005ec2:	6402                	ld	s0,0(sp)
    80005ec4:	0141                	addi	sp,sp,16
    80005ec6:	8082                	ret

0000000080005ec8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ec8:	1141                	addi	sp,sp,-16
    80005eca:	e406                	sd	ra,8(sp)
    80005ecc:	e022                	sd	s0,0(sp)
    80005ece:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed0:	ffffc097          	auipc	ra,0xffffc
    80005ed4:	c38080e7          	jalr	-968(ra) # 80001b08 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ed8:	00d5179b          	slliw	a5,a0,0xd
    80005edc:	0c201537          	lui	a0,0xc201
    80005ee0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ee2:	4148                	lw	a0,4(a0)
    80005ee4:	60a2                	ld	ra,8(sp)
    80005ee6:	6402                	ld	s0,0(sp)
    80005ee8:	0141                	addi	sp,sp,16
    80005eea:	8082                	ret

0000000080005eec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eec:	1101                	addi	sp,sp,-32
    80005eee:	ec06                	sd	ra,24(sp)
    80005ef0:	e822                	sd	s0,16(sp)
    80005ef2:	e426                	sd	s1,8(sp)
    80005ef4:	1000                	addi	s0,sp,32
    80005ef6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	c10080e7          	jalr	-1008(ra) # 80001b08 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f00:	00d5151b          	slliw	a0,a0,0xd
    80005f04:	0c2017b7          	lui	a5,0xc201
    80005f08:	97aa                	add	a5,a5,a0
    80005f0a:	c3c4                	sw	s1,4(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	addi	sp,sp,32
    80005f14:	8082                	ret

0000000080005f16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f16:	1141                	addi	sp,sp,-16
    80005f18:	e406                	sd	ra,8(sp)
    80005f1a:	e022                	sd	s0,0(sp)
    80005f1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f1e:	479d                	li	a5,7
    80005f20:	04a7cc63          	blt	a5,a0,80005f78 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f24:	0001c797          	auipc	a5,0x1c
    80005f28:	56c78793          	addi	a5,a5,1388 # 80022490 <disk>
    80005f2c:	97aa                	add	a5,a5,a0
    80005f2e:	0187c783          	lbu	a5,24(a5)
    80005f32:	ebb9                	bnez	a5,80005f88 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f34:	00451613          	slli	a2,a0,0x4
    80005f38:	0001c797          	auipc	a5,0x1c
    80005f3c:	55878793          	addi	a5,a5,1368 # 80022490 <disk>
    80005f40:	6394                	ld	a3,0(a5)
    80005f42:	96b2                	add	a3,a3,a2
    80005f44:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f48:	6398                	ld	a4,0(a5)
    80005f4a:	9732                	add	a4,a4,a2
    80005f4c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f50:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f54:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f58:	953e                	add	a0,a0,a5
    80005f5a:	4785                	li	a5,1
    80005f5c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f60:	0001c517          	auipc	a0,0x1c
    80005f64:	54850513          	addi	a0,a0,1352 # 800224a8 <disk+0x18>
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	2d8080e7          	jalr	728(ra) # 80002240 <wakeup>
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret
    panic("free_desc 1");
    80005f78:	00003517          	auipc	a0,0x3
    80005f7c:	80850513          	addi	a0,a0,-2040 # 80008780 <syscalls+0x300>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	746080e7          	jalr	1862(ra) # 800006c6 <panic>
    panic("free_desc 2");
    80005f88:	00003517          	auipc	a0,0x3
    80005f8c:	80850513          	addi	a0,a0,-2040 # 80008790 <syscalls+0x310>
    80005f90:	ffffa097          	auipc	ra,0xffffa
    80005f94:	736080e7          	jalr	1846(ra) # 800006c6 <panic>

0000000080005f98 <virtio_disk_init>:
{
    80005f98:	1101                	addi	sp,sp,-32
    80005f9a:	ec06                	sd	ra,24(sp)
    80005f9c:	e822                	sd	s0,16(sp)
    80005f9e:	e426                	sd	s1,8(sp)
    80005fa0:	e04a                	sd	s2,0(sp)
    80005fa2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fa4:	00002597          	auipc	a1,0x2
    80005fa8:	7fc58593          	addi	a1,a1,2044 # 800087a0 <syscalls+0x320>
    80005fac:	0001c517          	auipc	a0,0x1c
    80005fb0:	60c50513          	addi	a0,a0,1548 # 800225b8 <disk+0x128>
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	d1a080e7          	jalr	-742(ra) # 80000cce <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fbc:	100017b7          	lui	a5,0x10001
    80005fc0:	4398                	lw	a4,0(a5)
    80005fc2:	2701                	sext.w	a4,a4
    80005fc4:	747277b7          	lui	a5,0x74727
    80005fc8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fcc:	14f71c63          	bne	a4,a5,80006124 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fd0:	100017b7          	lui	a5,0x10001
    80005fd4:	43dc                	lw	a5,4(a5)
    80005fd6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fd8:	4709                	li	a4,2
    80005fda:	14e79563          	bne	a5,a4,80006124 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fde:	100017b7          	lui	a5,0x10001
    80005fe2:	479c                	lw	a5,8(a5)
    80005fe4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fe6:	12e79f63          	bne	a5,a4,80006124 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fea:	100017b7          	lui	a5,0x10001
    80005fee:	47d8                	lw	a4,12(a5)
    80005ff0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ff2:	554d47b7          	lui	a5,0x554d4
    80005ff6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ffa:	12f71563          	bne	a4,a5,80006124 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006006:	4705                	li	a4,1
    80006008:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600a:	470d                	li	a4,3
    8000600c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000600e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006010:	c7ffe737          	lui	a4,0xc7ffe
    80006014:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc18f>
    80006018:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000601a:	2701                	sext.w	a4,a4
    8000601c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000601e:	472d                	li	a4,11
    80006020:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006022:	5bbc                	lw	a5,112(a5)
    80006024:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006028:	8ba1                	andi	a5,a5,8
    8000602a:	10078563          	beqz	a5,80006134 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006036:	43fc                	lw	a5,68(a5)
    80006038:	2781                	sext.w	a5,a5
    8000603a:	10079563          	bnez	a5,80006144 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	5bdc                	lw	a5,52(a5)
    80006044:	2781                	sext.w	a5,a5
  if(max == 0)
    80006046:	10078763          	beqz	a5,80006154 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000604a:	471d                	li	a4,7
    8000604c:	10f77c63          	bgeu	a4,a5,80006164 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	c1e080e7          	jalr	-994(ra) # 80000c6e <kalloc>
    80006058:	0001c497          	auipc	s1,0x1c
    8000605c:	43848493          	addi	s1,s1,1080 # 80022490 <disk>
    80006060:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	c0c080e7          	jalr	-1012(ra) # 80000c6e <kalloc>
    8000606a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	c02080e7          	jalr	-1022(ra) # 80000c6e <kalloc>
    80006074:	87aa                	mv	a5,a0
    80006076:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006078:	6088                	ld	a0,0(s1)
    8000607a:	cd6d                	beqz	a0,80006174 <virtio_disk_init+0x1dc>
    8000607c:	0001c717          	auipc	a4,0x1c
    80006080:	41c73703          	ld	a4,1052(a4) # 80022498 <disk+0x8>
    80006084:	cb65                	beqz	a4,80006174 <virtio_disk_init+0x1dc>
    80006086:	c7fd                	beqz	a5,80006174 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006088:	6605                	lui	a2,0x1
    8000608a:	4581                	li	a1,0
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	dce080e7          	jalr	-562(ra) # 80000e5a <memset>
  memset(disk.avail, 0, PGSIZE);
    80006094:	0001c497          	auipc	s1,0x1c
    80006098:	3fc48493          	addi	s1,s1,1020 # 80022490 <disk>
    8000609c:	6605                	lui	a2,0x1
    8000609e:	4581                	li	a1,0
    800060a0:	6488                	ld	a0,8(s1)
    800060a2:	ffffb097          	auipc	ra,0xffffb
    800060a6:	db8080e7          	jalr	-584(ra) # 80000e5a <memset>
  memset(disk.used, 0, PGSIZE);
    800060aa:	6605                	lui	a2,0x1
    800060ac:	4581                	li	a1,0
    800060ae:	6888                	ld	a0,16(s1)
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	daa080e7          	jalr	-598(ra) # 80000e5a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060b8:	100017b7          	lui	a5,0x10001
    800060bc:	4721                	li	a4,8
    800060be:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060c0:	4098                	lw	a4,0(s1)
    800060c2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060c6:	40d8                	lw	a4,4(s1)
    800060c8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060cc:	6498                	ld	a4,8(s1)
    800060ce:	0007069b          	sext.w	a3,a4
    800060d2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060d6:	9701                	srai	a4,a4,0x20
    800060d8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060dc:	6898                	ld	a4,16(s1)
    800060de:	0007069b          	sext.w	a3,a4
    800060e2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060e6:	9701                	srai	a4,a4,0x20
    800060e8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060ec:	4705                	li	a4,1
    800060ee:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060f0:	00e48c23          	sb	a4,24(s1)
    800060f4:	00e48ca3          	sb	a4,25(s1)
    800060f8:	00e48d23          	sb	a4,26(s1)
    800060fc:	00e48da3          	sb	a4,27(s1)
    80006100:	00e48e23          	sb	a4,28(s1)
    80006104:	00e48ea3          	sb	a4,29(s1)
    80006108:	00e48f23          	sb	a4,30(s1)
    8000610c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006110:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006114:	0727a823          	sw	s2,112(a5)
}
    80006118:	60e2                	ld	ra,24(sp)
    8000611a:	6442                	ld	s0,16(sp)
    8000611c:	64a2                	ld	s1,8(sp)
    8000611e:	6902                	ld	s2,0(sp)
    80006120:	6105                	addi	sp,sp,32
    80006122:	8082                	ret
    panic("could not find virtio disk");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	68c50513          	addi	a0,a0,1676 # 800087b0 <syscalls+0x330>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	59a080e7          	jalr	1434(ra) # 800006c6 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	69c50513          	addi	a0,a0,1692 # 800087d0 <syscalls+0x350>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	58a080e7          	jalr	1418(ra) # 800006c6 <panic>
    panic("virtio disk should not be ready");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	6ac50513          	addi	a0,a0,1708 # 800087f0 <syscalls+0x370>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	57a080e7          	jalr	1402(ra) # 800006c6 <panic>
    panic("virtio disk has no queue 0");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	6bc50513          	addi	a0,a0,1724 # 80008810 <syscalls+0x390>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	56a080e7          	jalr	1386(ra) # 800006c6 <panic>
    panic("virtio disk max queue too short");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6cc50513          	addi	a0,a0,1740 # 80008830 <syscalls+0x3b0>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	55a080e7          	jalr	1370(ra) # 800006c6 <panic>
    panic("virtio disk kalloc");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6dc50513          	addi	a0,a0,1756 # 80008850 <syscalls+0x3d0>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	54a080e7          	jalr	1354(ra) # 800006c6 <panic>

0000000080006184 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006184:	7119                	addi	sp,sp,-128
    80006186:	fc86                	sd	ra,120(sp)
    80006188:	f8a2                	sd	s0,112(sp)
    8000618a:	f4a6                	sd	s1,104(sp)
    8000618c:	f0ca                	sd	s2,96(sp)
    8000618e:	ecce                	sd	s3,88(sp)
    80006190:	e8d2                	sd	s4,80(sp)
    80006192:	e4d6                	sd	s5,72(sp)
    80006194:	e0da                	sd	s6,64(sp)
    80006196:	fc5e                	sd	s7,56(sp)
    80006198:	f862                	sd	s8,48(sp)
    8000619a:	f466                	sd	s9,40(sp)
    8000619c:	f06a                	sd	s10,32(sp)
    8000619e:	ec6e                	sd	s11,24(sp)
    800061a0:	0100                	addi	s0,sp,128
    800061a2:	8aaa                	mv	s5,a0
    800061a4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061a6:	00c52d03          	lw	s10,12(a0)
    800061aa:	001d1d1b          	slliw	s10,s10,0x1
    800061ae:	1d02                	slli	s10,s10,0x20
    800061b0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800061b4:	0001c517          	auipc	a0,0x1c
    800061b8:	40450513          	addi	a0,a0,1028 # 800225b8 <disk+0x128>
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	ba2080e7          	jalr	-1118(ra) # 80000d5e <acquire>
  for(int i = 0; i < 3; i++){
    800061c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061c6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061c8:	0001cb97          	auipc	s7,0x1c
    800061cc:	2c8b8b93          	addi	s7,s7,712 # 80022490 <disk>
  for(int i = 0; i < 3; i++){
    800061d0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d2:	0001cc97          	auipc	s9,0x1c
    800061d6:	3e6c8c93          	addi	s9,s9,998 # 800225b8 <disk+0x128>
    800061da:	a08d                	j	8000623c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061dc:	00fb8733          	add	a4,s7,a5
    800061e0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061e4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061e6:	0207c563          	bltz	a5,80006210 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061ea:	2905                	addiw	s2,s2,1
    800061ec:	0611                	addi	a2,a2,4
    800061ee:	05690c63          	beq	s2,s6,80006246 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061f2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061f4:	0001c717          	auipc	a4,0x1c
    800061f8:	29c70713          	addi	a4,a4,668 # 80022490 <disk>
    800061fc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061fe:	01874683          	lbu	a3,24(a4)
    80006202:	fee9                	bnez	a3,800061dc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006204:	2785                	addiw	a5,a5,1
    80006206:	0705                	addi	a4,a4,1
    80006208:	fe979be3          	bne	a5,s1,800061fe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000620c:	57fd                	li	a5,-1
    8000620e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006210:	01205d63          	blez	s2,8000622a <virtio_disk_rw+0xa6>
    80006214:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006216:	000a2503          	lw	a0,0(s4)
    8000621a:	00000097          	auipc	ra,0x0
    8000621e:	cfc080e7          	jalr	-772(ra) # 80005f16 <free_desc>
      for(int j = 0; j < i; j++)
    80006222:	2d85                	addiw	s11,s11,1
    80006224:	0a11                	addi	s4,s4,4
    80006226:	ffb918e3          	bne	s2,s11,80006216 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000622a:	85e6                	mv	a1,s9
    8000622c:	0001c517          	auipc	a0,0x1c
    80006230:	27c50513          	addi	a0,a0,636 # 800224a8 <disk+0x18>
    80006234:	ffffc097          	auipc	ra,0xffffc
    80006238:	fa8080e7          	jalr	-88(ra) # 800021dc <sleep>
  for(int i = 0; i < 3; i++){
    8000623c:	f8040a13          	addi	s4,s0,-128
{
    80006240:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006242:	894e                	mv	s2,s3
    80006244:	b77d                	j	800061f2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006246:	f8042583          	lw	a1,-128(s0)
    8000624a:	00a58793          	addi	a5,a1,10
    8000624e:	0792                	slli	a5,a5,0x4

  if(write)
    80006250:	0001c617          	auipc	a2,0x1c
    80006254:	24060613          	addi	a2,a2,576 # 80022490 <disk>
    80006258:	00f60733          	add	a4,a2,a5
    8000625c:	018036b3          	snez	a3,s8
    80006260:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006262:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006266:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000626a:	f6078693          	addi	a3,a5,-160
    8000626e:	6218                	ld	a4,0(a2)
    80006270:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006272:	00878513          	addi	a0,a5,8
    80006276:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006278:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000627a:	6208                	ld	a0,0(a2)
    8000627c:	96aa                	add	a3,a3,a0
    8000627e:	4741                	li	a4,16
    80006280:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006282:	4705                	li	a4,1
    80006284:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006288:	f8442703          	lw	a4,-124(s0)
    8000628c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006290:	0712                	slli	a4,a4,0x4
    80006292:	953a                	add	a0,a0,a4
    80006294:	058a8693          	addi	a3,s5,88
    80006298:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000629a:	6208                	ld	a0,0(a2)
    8000629c:	972a                	add	a4,a4,a0
    8000629e:	40000693          	li	a3,1024
    800062a2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062a4:	001c3c13          	seqz	s8,s8
    800062a8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062aa:	001c6c13          	ori	s8,s8,1
    800062ae:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800062b2:	f8842603          	lw	a2,-120(s0)
    800062b6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062ba:	0001c697          	auipc	a3,0x1c
    800062be:	1d668693          	addi	a3,a3,470 # 80022490 <disk>
    800062c2:	00258713          	addi	a4,a1,2
    800062c6:	0712                	slli	a4,a4,0x4
    800062c8:	9736                	add	a4,a4,a3
    800062ca:	587d                	li	a6,-1
    800062cc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062d0:	0612                	slli	a2,a2,0x4
    800062d2:	9532                	add	a0,a0,a2
    800062d4:	f9078793          	addi	a5,a5,-112
    800062d8:	97b6                	add	a5,a5,a3
    800062da:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800062dc:	629c                	ld	a5,0(a3)
    800062de:	97b2                	add	a5,a5,a2
    800062e0:	4605                	li	a2,1
    800062e2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062e4:	4509                	li	a0,2
    800062e6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800062ea:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062ee:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062f2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062f6:	6698                	ld	a4,8(a3)
    800062f8:	00275783          	lhu	a5,2(a4)
    800062fc:	8b9d                	andi	a5,a5,7
    800062fe:	0786                	slli	a5,a5,0x1
    80006300:	97ba                	add	a5,a5,a4
    80006302:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006306:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000630a:	6698                	ld	a4,8(a3)
    8000630c:	00275783          	lhu	a5,2(a4)
    80006310:	2785                	addiw	a5,a5,1
    80006312:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006316:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000631a:	100017b7          	lui	a5,0x10001
    8000631e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006322:	004aa783          	lw	a5,4(s5)
    80006326:	02c79163          	bne	a5,a2,80006348 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000632a:	0001c917          	auipc	s2,0x1c
    8000632e:	28e90913          	addi	s2,s2,654 # 800225b8 <disk+0x128>
  while(b->disk == 1) {
    80006332:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006334:	85ca                	mv	a1,s2
    80006336:	8556                	mv	a0,s5
    80006338:	ffffc097          	auipc	ra,0xffffc
    8000633c:	ea4080e7          	jalr	-348(ra) # 800021dc <sleep>
  while(b->disk == 1) {
    80006340:	004aa783          	lw	a5,4(s5)
    80006344:	fe9788e3          	beq	a5,s1,80006334 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006348:	f8042903          	lw	s2,-128(s0)
    8000634c:	00290793          	addi	a5,s2,2
    80006350:	00479713          	slli	a4,a5,0x4
    80006354:	0001c797          	auipc	a5,0x1c
    80006358:	13c78793          	addi	a5,a5,316 # 80022490 <disk>
    8000635c:	97ba                	add	a5,a5,a4
    8000635e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006362:	0001c997          	auipc	s3,0x1c
    80006366:	12e98993          	addi	s3,s3,302 # 80022490 <disk>
    8000636a:	00491713          	slli	a4,s2,0x4
    8000636e:	0009b783          	ld	a5,0(s3)
    80006372:	97ba                	add	a5,a5,a4
    80006374:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006378:	854a                	mv	a0,s2
    8000637a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000637e:	00000097          	auipc	ra,0x0
    80006382:	b98080e7          	jalr	-1128(ra) # 80005f16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006386:	8885                	andi	s1,s1,1
    80006388:	f0ed                	bnez	s1,8000636a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000638a:	0001c517          	auipc	a0,0x1c
    8000638e:	22e50513          	addi	a0,a0,558 # 800225b8 <disk+0x128>
    80006392:	ffffb097          	auipc	ra,0xffffb
    80006396:	a80080e7          	jalr	-1408(ra) # 80000e12 <release>
}
    8000639a:	70e6                	ld	ra,120(sp)
    8000639c:	7446                	ld	s0,112(sp)
    8000639e:	74a6                	ld	s1,104(sp)
    800063a0:	7906                	ld	s2,96(sp)
    800063a2:	69e6                	ld	s3,88(sp)
    800063a4:	6a46                	ld	s4,80(sp)
    800063a6:	6aa6                	ld	s5,72(sp)
    800063a8:	6b06                	ld	s6,64(sp)
    800063aa:	7be2                	ld	s7,56(sp)
    800063ac:	7c42                	ld	s8,48(sp)
    800063ae:	7ca2                	ld	s9,40(sp)
    800063b0:	7d02                	ld	s10,32(sp)
    800063b2:	6de2                	ld	s11,24(sp)
    800063b4:	6109                	addi	sp,sp,128
    800063b6:	8082                	ret

00000000800063b8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063b8:	1101                	addi	sp,sp,-32
    800063ba:	ec06                	sd	ra,24(sp)
    800063bc:	e822                	sd	s0,16(sp)
    800063be:	e426                	sd	s1,8(sp)
    800063c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063c2:	0001c497          	auipc	s1,0x1c
    800063c6:	0ce48493          	addi	s1,s1,206 # 80022490 <disk>
    800063ca:	0001c517          	auipc	a0,0x1c
    800063ce:	1ee50513          	addi	a0,a0,494 # 800225b8 <disk+0x128>
    800063d2:	ffffb097          	auipc	ra,0xffffb
    800063d6:	98c080e7          	jalr	-1652(ra) # 80000d5e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063da:	10001737          	lui	a4,0x10001
    800063de:	533c                	lw	a5,96(a4)
    800063e0:	8b8d                	andi	a5,a5,3
    800063e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063e8:	689c                	ld	a5,16(s1)
    800063ea:	0204d703          	lhu	a4,32(s1)
    800063ee:	0027d783          	lhu	a5,2(a5)
    800063f2:	04f70863          	beq	a4,a5,80006442 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063f6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063fa:	6898                	ld	a4,16(s1)
    800063fc:	0204d783          	lhu	a5,32(s1)
    80006400:	8b9d                	andi	a5,a5,7
    80006402:	078e                	slli	a5,a5,0x3
    80006404:	97ba                	add	a5,a5,a4
    80006406:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006408:	00278713          	addi	a4,a5,2
    8000640c:	0712                	slli	a4,a4,0x4
    8000640e:	9726                	add	a4,a4,s1
    80006410:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006414:	e721                	bnez	a4,8000645c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006416:	0789                	addi	a5,a5,2
    80006418:	0792                	slli	a5,a5,0x4
    8000641a:	97a6                	add	a5,a5,s1
    8000641c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000641e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006422:	ffffc097          	auipc	ra,0xffffc
    80006426:	e1e080e7          	jalr	-482(ra) # 80002240 <wakeup>

    disk.used_idx += 1;
    8000642a:	0204d783          	lhu	a5,32(s1)
    8000642e:	2785                	addiw	a5,a5,1
    80006430:	17c2                	slli	a5,a5,0x30
    80006432:	93c1                	srli	a5,a5,0x30
    80006434:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006438:	6898                	ld	a4,16(s1)
    8000643a:	00275703          	lhu	a4,2(a4)
    8000643e:	faf71ce3          	bne	a4,a5,800063f6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006442:	0001c517          	auipc	a0,0x1c
    80006446:	17650513          	addi	a0,a0,374 # 800225b8 <disk+0x128>
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	9c8080e7          	jalr	-1592(ra) # 80000e12 <release>
}
    80006452:	60e2                	ld	ra,24(sp)
    80006454:	6442                	ld	s0,16(sp)
    80006456:	64a2                	ld	s1,8(sp)
    80006458:	6105                	addi	sp,sp,32
    8000645a:	8082                	ret
      panic("virtio_disk_intr status");
    8000645c:	00002517          	auipc	a0,0x2
    80006460:	40c50513          	addi	a0,a0,1036 # 80008868 <syscalls+0x3e8>
    80006464:	ffffa097          	auipc	ra,0xffffa
    80006468:	262080e7          	jalr	610(ra) # 800006c6 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
