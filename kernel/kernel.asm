
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16

static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	d0478793          	addi	a5,a5,-764 # 80005d60 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e7678793          	addi	a5,a5,-394 # 80000f1c <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b66080e7          	jalr	-1178(ra) # 80000c72 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	414080e7          	jalr	1044(ra) # 8000253a <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	80a080e7          	jalr	-2038(ra) # 80000940 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bd8080e7          	jalr	-1064(ra) # 80000d26 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	ad6080e7          	jalr	-1322(ra) # 80000c72 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	874080e7          	jalr	-1932(ra) # 80001a3e <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	0b0080e7          	jalr	176(ra) # 8000228a <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	2ce080e7          	jalr	718(ra) # 800024e4 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	af4080e7          	jalr	-1292(ra) # 80000d26 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	ade080e7          	jalr	-1314(ra) # 80000d26 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	5d2080e7          	jalr	1490(ra) # 80000862 <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	5c0080e7          	jalr	1472(ra) # 80000862 <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	5b4080e7          	jalr	1460(ra) # 80000862 <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	5aa080e7          	jalr	1450(ra) # 80000862 <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	99a080e7          	jalr	-1638(ra) # 80000c72 <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	29a080e7          	jalr	666(ra) # 80002590 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	a20080e7          	jalr	-1504(ra) # 80000d26 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	fc0080e7          	jalr	-64(ra) # 8000240a <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	776080e7          	jalr	1910(ra) # 80000be2 <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	39e080e7          	jalr	926(ra) # 80000812 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00022797          	auipc	a5,0x22
    80000480:	d3478793          	addi	a5,a5,-716 # 800221b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b9a60613          	addi	a2,a2,-1126 # 80008058 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000054c:	00011497          	auipc	s1,0x11
    80000550:	38c48493          	addi	s1,s1,908 # 800118d8 <pr>
    80000554:	00008597          	auipc	a1,0x8
    80000558:	ac458593          	addi	a1,a1,-1340 # 80008018 <etext+0x18>
    8000055c:	8526                	mv	a0,s1
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	684080e7          	jalr	1668(ra) # 80000be2 <initlock>
  pr.locking = 1;
    80000566:	4785                	li	a5,1
    80000568:	cc9c                	sw	a5,24(s1)
}
    8000056a:	60e2                	ld	ra,24(sp)
    8000056c:	6442                	ld	s0,16(sp)
    8000056e:	64a2                	ld	s1,8(sp)
    80000570:	6105                	addi	sp,sp,32
    80000572:	8082                	ret

0000000080000574 <backtrace>:

void
backtrace()
{
    80000574:	7179                	addi	sp,sp,-48
    80000576:	f406                	sd	ra,40(sp)
    80000578:	f022                	sd	s0,32(sp)
    8000057a:	ec26                	sd	s1,24(sp)
    8000057c:	e84a                	sd	s2,16(sp)
    8000057e:	e44e                	sd	s3,8(sp)
    80000580:	e052                	sd	s4,0(sp)
    80000582:	1800                	addi	s0,sp,48
  printf("backtrace:\n");
    80000584:	00008517          	auipc	a0,0x8
    80000588:	a9c50513          	addi	a0,a0,-1380 # 80008020 <etext+0x20>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	0a6080e7          	jalr	166(ra) # 80000632 <printf>
  asm volatile("mv %0, s0": "=r"(x));
    80000594:	84a2                	mv	s1,s0
  uint64 fp=r_fp();
  while(fp!=PGROUNDUP(fp))
    80000596:	6785                	lui	a5,0x1
    80000598:	17fd                	addi	a5,a5,-1
    8000059a:	97a6                	add	a5,a5,s1
    8000059c:	777d                	lui	a4,0xfffff
    8000059e:	8ff9                	and	a5,a5,a4
    800005a0:	02f48863          	beq	s1,a5,800005d0 <backtrace+0x5c>
  {
    uint64 tmp=*(uint64 *)(fp-8);
    printf("%p\n",tmp);
    800005a4:	00008a17          	auipc	s4,0x8
    800005a8:	a8ca0a13          	addi	s4,s4,-1396 # 80008030 <etext+0x30>
  while(fp!=PGROUNDUP(fp))
    800005ac:	6905                	lui	s2,0x1
    800005ae:	197d                	addi	s2,s2,-1
    800005b0:	79fd                	lui	s3,0xfffff
    printf("%p\n",tmp);
    800005b2:	ff84b583          	ld	a1,-8(s1)
    800005b6:	8552                	mv	a0,s4
    800005b8:	00000097          	auipc	ra,0x0
    800005bc:	07a080e7          	jalr	122(ra) # 80000632 <printf>
    fp=*(uint64 *)(fp-16);
    800005c0:	ff04b483          	ld	s1,-16(s1)
  while(fp!=PGROUNDUP(fp))
    800005c4:	012487b3          	add	a5,s1,s2
    800005c8:	0137f7b3          	and	a5,a5,s3
    800005cc:	fe9793e3          	bne	a5,s1,800005b2 <backtrace+0x3e>
  }
  return;
}
    800005d0:	70a2                	ld	ra,40(sp)
    800005d2:	7402                	ld	s0,32(sp)
    800005d4:	64e2                	ld	s1,24(sp)
    800005d6:	6942                	ld	s2,16(sp)
    800005d8:	69a2                	ld	s3,8(sp)
    800005da:	6a02                	ld	s4,0(sp)
    800005dc:	6145                	addi	sp,sp,48
    800005de:	8082                	ret

00000000800005e0 <panic>:
{
    800005e0:	1101                	addi	sp,sp,-32
    800005e2:	ec06                	sd	ra,24(sp)
    800005e4:	e822                	sd	s0,16(sp)
    800005e6:	e426                	sd	s1,8(sp)
    800005e8:	1000                	addi	s0,sp,32
    800005ea:	84aa                	mv	s1,a0
  backtrace();
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	f88080e7          	jalr	-120(ra) # 80000574 <backtrace>
  pr.locking = 0;
    800005f4:	00011797          	auipc	a5,0x11
    800005f8:	2e07ae23          	sw	zero,764(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a3c50513          	addi	a0,a0,-1476 # 80008038 <etext+0x38>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	02e080e7          	jalr	46(ra) # 80000632 <printf>
  printf(s);
    8000060c:	8526                	mv	a0,s1
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	024080e7          	jalr	36(ra) # 80000632 <printf>
  printf("\n");
    80000616:	00008517          	auipc	a0,0x8
    8000061a:	aca50513          	addi	a0,a0,-1334 # 800080e0 <digits+0x88>
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	014080e7          	jalr	20(ra) # 80000632 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000626:	4785                	li	a5,1
    80000628:	00009717          	auipc	a4,0x9
    8000062c:	9cf72c23          	sw	a5,-1576(a4) # 80009000 <panicked>
  for(;;)
    80000630:	a001                	j	80000630 <panic+0x50>

0000000080000632 <printf>:
{
    80000632:	7131                	addi	sp,sp,-192
    80000634:	fc86                	sd	ra,120(sp)
    80000636:	f8a2                	sd	s0,112(sp)
    80000638:	f4a6                	sd	s1,104(sp)
    8000063a:	f0ca                	sd	s2,96(sp)
    8000063c:	ecce                	sd	s3,88(sp)
    8000063e:	e8d2                	sd	s4,80(sp)
    80000640:	e4d6                	sd	s5,72(sp)
    80000642:	e0da                	sd	s6,64(sp)
    80000644:	fc5e                	sd	s7,56(sp)
    80000646:	f862                	sd	s8,48(sp)
    80000648:	f466                	sd	s9,40(sp)
    8000064a:	f06a                	sd	s10,32(sp)
    8000064c:	ec6e                	sd	s11,24(sp)
    8000064e:	0100                	addi	s0,sp,128
    80000650:	8a2a                	mv	s4,a0
    80000652:	e40c                	sd	a1,8(s0)
    80000654:	e810                	sd	a2,16(s0)
    80000656:	ec14                	sd	a3,24(s0)
    80000658:	f018                	sd	a4,32(s0)
    8000065a:	f41c                	sd	a5,40(s0)
    8000065c:	03043823          	sd	a6,48(s0)
    80000660:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000664:	00011d97          	auipc	s11,0x11
    80000668:	28cdad83          	lw	s11,652(s11) # 800118f0 <pr+0x18>
  if(locking)
    8000066c:	020d9b63          	bnez	s11,800006a2 <printf+0x70>
  if (fmt == 0)
    80000670:	040a0263          	beqz	s4,800006b4 <printf+0x82>
  va_start(ap, fmt);
    80000674:	00840793          	addi	a5,s0,8
    80000678:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000067c:	000a4503          	lbu	a0,0(s4)
    80000680:	14050f63          	beqz	a0,800007de <printf+0x1ac>
    80000684:	4981                	li	s3,0
    if(c != '%'){
    80000686:	02500a93          	li	s5,37
    switch(c){
    8000068a:	07000b93          	li	s7,112
  consputc('x');
    8000068e:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000690:	00008b17          	auipc	s6,0x8
    80000694:	9c8b0b13          	addi	s6,s6,-1592 # 80008058 <digits>
    switch(c){
    80000698:	07300c93          	li	s9,115
    8000069c:	06400c13          	li	s8,100
    800006a0:	a82d                	j	800006da <printf+0xa8>
    acquire(&pr.lock);
    800006a2:	00011517          	auipc	a0,0x11
    800006a6:	23650513          	addi	a0,a0,566 # 800118d8 <pr>
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	5c8080e7          	jalr	1480(ra) # 80000c72 <acquire>
    800006b2:	bf7d                	j	80000670 <printf+0x3e>
    panic("null fmt");
    800006b4:	00008517          	auipc	a0,0x8
    800006b8:	99450513          	addi	a0,a0,-1644 # 80008048 <etext+0x48>
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	f24080e7          	jalr	-220(ra) # 800005e0 <panic>
      consputc(c);
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bbc080e7          	jalr	-1092(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006cc:	2985                	addiw	s3,s3,1
    800006ce:	013a07b3          	add	a5,s4,s3
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	10050463          	beqz	a0,800007de <printf+0x1ac>
    if(c != '%'){
    800006da:	ff5515e3          	bne	a0,s5,800006c4 <printf+0x92>
    c = fmt[++i] & 0xff;
    800006de:	2985                	addiw	s3,s3,1
    800006e0:	013a07b3          	add	a5,s4,s3
    800006e4:	0007c783          	lbu	a5,0(a5)
    800006e8:	0007849b          	sext.w	s1,a5
    if(c == 0)
    800006ec:	cbed                	beqz	a5,800007de <printf+0x1ac>
    switch(c){
    800006ee:	05778a63          	beq	a5,s7,80000742 <printf+0x110>
    800006f2:	02fbf663          	bgeu	s7,a5,8000071e <printf+0xec>
    800006f6:	09978863          	beq	a5,s9,80000786 <printf+0x154>
    800006fa:	07800713          	li	a4,120
    800006fe:	0ce79563          	bne	a5,a4,800007c8 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000702:	f8843783          	ld	a5,-120(s0)
    80000706:	00878713          	addi	a4,a5,8
    8000070a:	f8e43423          	sd	a4,-120(s0)
    8000070e:	4605                	li	a2,1
    80000710:	85ea                	mv	a1,s10
    80000712:	4388                	lw	a0,0(a5)
    80000714:	00000097          	auipc	ra,0x0
    80000718:	d8c080e7          	jalr	-628(ra) # 800004a0 <printint>
      break;
    8000071c:	bf45                	j	800006cc <printf+0x9a>
    switch(c){
    8000071e:	09578f63          	beq	a5,s5,800007bc <printf+0x18a>
    80000722:	0b879363          	bne	a5,s8,800007c8 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000726:	f8843783          	ld	a5,-120(s0)
    8000072a:	00878713          	addi	a4,a5,8
    8000072e:	f8e43423          	sd	a4,-120(s0)
    80000732:	4605                	li	a2,1
    80000734:	45a9                	li	a1,10
    80000736:	4388                	lw	a0,0(a5)
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	d68080e7          	jalr	-664(ra) # 800004a0 <printint>
      break;
    80000740:	b771                	j	800006cc <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000742:	f8843783          	ld	a5,-120(s0)
    80000746:	00878713          	addi	a4,a5,8
    8000074a:	f8e43423          	sd	a4,-120(s0)
    8000074e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000752:	03000513          	li	a0,48
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b2a080e7          	jalr	-1238(ra) # 80000280 <consputc>
  consputc('x');
    8000075e:	07800513          	li	a0,120
    80000762:	00000097          	auipc	ra,0x0
    80000766:	b1e080e7          	jalr	-1250(ra) # 80000280 <consputc>
    8000076a:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000076c:	03c95793          	srli	a5,s2,0x3c
    80000770:	97da                	add	a5,a5,s6
    80000772:	0007c503          	lbu	a0,0(a5)
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	b0a080e7          	jalr	-1270(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000077e:	0912                	slli	s2,s2,0x4
    80000780:	34fd                	addiw	s1,s1,-1
    80000782:	f4ed                	bnez	s1,8000076c <printf+0x13a>
    80000784:	b7a1                	j	800006cc <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000786:	f8843783          	ld	a5,-120(s0)
    8000078a:	00878713          	addi	a4,a5,8
    8000078e:	f8e43423          	sd	a4,-120(s0)
    80000792:	6384                	ld	s1,0(a5)
    80000794:	cc89                	beqz	s1,800007ae <printf+0x17c>
      for(; *s; s++)
    80000796:	0004c503          	lbu	a0,0(s1)
    8000079a:	d90d                	beqz	a0,800006cc <printf+0x9a>
        consputc(*s);
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	ae4080e7          	jalr	-1308(ra) # 80000280 <consputc>
      for(; *s; s++)
    800007a4:	0485                	addi	s1,s1,1
    800007a6:	0004c503          	lbu	a0,0(s1)
    800007aa:	f96d                	bnez	a0,8000079c <printf+0x16a>
    800007ac:	b705                	j	800006cc <printf+0x9a>
        s = "(null)";
    800007ae:	00008497          	auipc	s1,0x8
    800007b2:	89248493          	addi	s1,s1,-1902 # 80008040 <etext+0x40>
      for(; *s; s++)
    800007b6:	02800513          	li	a0,40
    800007ba:	b7cd                	j	8000079c <printf+0x16a>
      consputc('%');
    800007bc:	8556                	mv	a0,s5
    800007be:	00000097          	auipc	ra,0x0
    800007c2:	ac2080e7          	jalr	-1342(ra) # 80000280 <consputc>
      break;
    800007c6:	b719                	j	800006cc <printf+0x9a>
      consputc('%');
    800007c8:	8556                	mv	a0,s5
    800007ca:	00000097          	auipc	ra,0x0
    800007ce:	ab6080e7          	jalr	-1354(ra) # 80000280 <consputc>
      consputc(c);
    800007d2:	8526                	mv	a0,s1
    800007d4:	00000097          	auipc	ra,0x0
    800007d8:	aac080e7          	jalr	-1364(ra) # 80000280 <consputc>
      break;
    800007dc:	bdc5                	j	800006cc <printf+0x9a>
  if(locking)
    800007de:	020d9163          	bnez	s11,80000800 <printf+0x1ce>
}
    800007e2:	70e6                	ld	ra,120(sp)
    800007e4:	7446                	ld	s0,112(sp)
    800007e6:	74a6                	ld	s1,104(sp)
    800007e8:	7906                	ld	s2,96(sp)
    800007ea:	69e6                	ld	s3,88(sp)
    800007ec:	6a46                	ld	s4,80(sp)
    800007ee:	6aa6                	ld	s5,72(sp)
    800007f0:	6b06                	ld	s6,64(sp)
    800007f2:	7be2                	ld	s7,56(sp)
    800007f4:	7c42                	ld	s8,48(sp)
    800007f6:	7ca2                	ld	s9,40(sp)
    800007f8:	7d02                	ld	s10,32(sp)
    800007fa:	6de2                	ld	s11,24(sp)
    800007fc:	6129                	addi	sp,sp,192
    800007fe:	8082                	ret
    release(&pr.lock);
    80000800:	00011517          	auipc	a0,0x11
    80000804:	0d850513          	addi	a0,a0,216 # 800118d8 <pr>
    80000808:	00000097          	auipc	ra,0x0
    8000080c:	51e080e7          	jalr	1310(ra) # 80000d26 <release>
}
    80000810:	bfc9                	j	800007e2 <printf+0x1b0>

0000000080000812 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000812:	1141                	addi	sp,sp,-16
    80000814:	e406                	sd	ra,8(sp)
    80000816:	e022                	sd	s0,0(sp)
    80000818:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000822:	f8000713          	li	a4,-128
    80000826:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000082a:	470d                	li	a4,3
    8000082c:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000830:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000834:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000838:	469d                	li	a3,7
    8000083a:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000083e:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000842:	00008597          	auipc	a1,0x8
    80000846:	82e58593          	addi	a1,a1,-2002 # 80008070 <digits+0x18>
    8000084a:	00011517          	auipc	a0,0x11
    8000084e:	0ae50513          	addi	a0,a0,174 # 800118f8 <uart_tx_lock>
    80000852:	00000097          	auipc	ra,0x0
    80000856:	390080e7          	jalr	912(ra) # 80000be2 <initlock>
}
    8000085a:	60a2                	ld	ra,8(sp)
    8000085c:	6402                	ld	s0,0(sp)
    8000085e:	0141                	addi	sp,sp,16
    80000860:	8082                	ret

0000000080000862 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000862:	1101                	addi	sp,sp,-32
    80000864:	ec06                	sd	ra,24(sp)
    80000866:	e822                	sd	s0,16(sp)
    80000868:	e426                	sd	s1,8(sp)
    8000086a:	1000                	addi	s0,sp,32
    8000086c:	84aa                	mv	s1,a0
  push_off();
    8000086e:	00000097          	auipc	ra,0x0
    80000872:	3b8080e7          	jalr	952(ra) # 80000c26 <push_off>

  if(panicked){
    80000876:	00008797          	auipc	a5,0x8
    8000087a:	78a7a783          	lw	a5,1930(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000882:	c391                	beqz	a5,80000886 <uartputc_sync+0x24>
    for(;;)
    80000884:	a001                	j	80000884 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000886:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	dfe5                	beqz	a5,80000886 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000890:	0ff4f513          	andi	a0,s1,255
    80000894:	100007b7          	lui	a5,0x10000
    80000898:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000089c:	00000097          	auipc	ra,0x0
    800008a0:	42a080e7          	jalr	1066(ra) # 80000cc6 <pop_off>
}
    800008a4:	60e2                	ld	ra,24(sp)
    800008a6:	6442                	ld	s0,16(sp)
    800008a8:	64a2                	ld	s1,8(sp)
    800008aa:	6105                	addi	sp,sp,32
    800008ac:	8082                	ret

00000000800008ae <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008ae:	00008797          	auipc	a5,0x8
    800008b2:	7567a783          	lw	a5,1878(a5) # 80009004 <uart_tx_r>
    800008b6:	00008717          	auipc	a4,0x8
    800008ba:	75272703          	lw	a4,1874(a4) # 80009008 <uart_tx_w>
    800008be:	08f70063          	beq	a4,a5,8000093e <uartstart+0x90>
{
    800008c2:	7139                	addi	sp,sp,-64
    800008c4:	fc06                	sd	ra,56(sp)
    800008c6:	f822                	sd	s0,48(sp)
    800008c8:	f426                	sd	s1,40(sp)
    800008ca:	f04a                	sd	s2,32(sp)
    800008cc:	ec4e                	sd	s3,24(sp)
    800008ce:	e852                	sd	s4,16(sp)
    800008d0:	e456                	sd	s5,8(sp)
    800008d2:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008d8:	00011a97          	auipc	s5,0x11
    800008dc:	020a8a93          	addi	s5,s5,32 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008e0:	00008497          	auipc	s1,0x8
    800008e4:	72448493          	addi	s1,s1,1828 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e8:	00008a17          	auipc	s4,0x8
    800008ec:	720a0a13          	addi	s4,s4,1824 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008f0:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f4:	02077713          	andi	a4,a4,32
    800008f8:	cb15                	beqz	a4,8000092c <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    800008fa:	00fa8733          	add	a4,s5,a5
    800008fe:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000902:	2785                	addiw	a5,a5,1
    80000904:	41f7d71b          	sraiw	a4,a5,0x1f
    80000908:	01b7571b          	srliw	a4,a4,0x1b
    8000090c:	9fb9                	addw	a5,a5,a4
    8000090e:	8bfd                	andi	a5,a5,31
    80000910:	9f99                	subw	a5,a5,a4
    80000912:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000914:	8526                	mv	a0,s1
    80000916:	00002097          	auipc	ra,0x2
    8000091a:	af4080e7          	jalr	-1292(ra) # 8000240a <wakeup>
    
    WriteReg(THR, c);
    8000091e:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000922:	409c                	lw	a5,0(s1)
    80000924:	000a2703          	lw	a4,0(s4)
    80000928:	fcf714e3          	bne	a4,a5,800008f0 <uartstart+0x42>
  }
}
    8000092c:	70e2                	ld	ra,56(sp)
    8000092e:	7442                	ld	s0,48(sp)
    80000930:	74a2                	ld	s1,40(sp)
    80000932:	7902                	ld	s2,32(sp)
    80000934:	69e2                	ld	s3,24(sp)
    80000936:	6a42                	ld	s4,16(sp)
    80000938:	6aa2                	ld	s5,8(sp)
    8000093a:	6121                	addi	sp,sp,64
    8000093c:	8082                	ret
    8000093e:	8082                	ret

0000000080000940 <uartputc>:
{
    80000940:	7179                	addi	sp,sp,-48
    80000942:	f406                	sd	ra,40(sp)
    80000944:	f022                	sd	s0,32(sp)
    80000946:	ec26                	sd	s1,24(sp)
    80000948:	e84a                	sd	s2,16(sp)
    8000094a:	e44e                	sd	s3,8(sp)
    8000094c:	e052                	sd	s4,0(sp)
    8000094e:	1800                	addi	s0,sp,48
    80000950:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    80000952:	00011517          	auipc	a0,0x11
    80000956:	fa650513          	addi	a0,a0,-90 # 800118f8 <uart_tx_lock>
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	318080e7          	jalr	792(ra) # 80000c72 <acquire>
  if(panicked){
    80000962:	00008797          	auipc	a5,0x8
    80000966:	69e7a783          	lw	a5,1694(a5) # 80009000 <panicked>
    8000096a:	c391                	beqz	a5,8000096e <uartputc+0x2e>
    for(;;)
    8000096c:	a001                	j	8000096c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000096e:	00008697          	auipc	a3,0x8
    80000972:	69a6a683          	lw	a3,1690(a3) # 80009008 <uart_tx_w>
    80000976:	0016879b          	addiw	a5,a3,1
    8000097a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000097e:	01b7571b          	srliw	a4,a4,0x1b
    80000982:	9fb9                	addw	a5,a5,a4
    80000984:	8bfd                	andi	a5,a5,31
    80000986:	9f99                	subw	a5,a5,a4
    80000988:	00008717          	auipc	a4,0x8
    8000098c:	67c72703          	lw	a4,1660(a4) # 80009004 <uart_tx_r>
    80000990:	04f71363          	bne	a4,a5,800009d6 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000994:	00011a17          	auipc	s4,0x11
    80000998:	f64a0a13          	addi	s4,s4,-156 # 800118f8 <uart_tx_lock>
    8000099c:	00008917          	auipc	s2,0x8
    800009a0:	66890913          	addi	s2,s2,1640 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a4:	00008997          	auipc	s3,0x8
    800009a8:	66498993          	addi	s3,s3,1636 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009ac:	85d2                	mv	a1,s4
    800009ae:	854a                	mv	a0,s2
    800009b0:	00002097          	auipc	ra,0x2
    800009b4:	8da080e7          	jalr	-1830(ra) # 8000228a <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009b8:	0009a683          	lw	a3,0(s3)
    800009bc:	0016879b          	addiw	a5,a3,1
    800009c0:	41f7d71b          	sraiw	a4,a5,0x1f
    800009c4:	01b7571b          	srliw	a4,a4,0x1b
    800009c8:	9fb9                	addw	a5,a5,a4
    800009ca:	8bfd                	andi	a5,a5,31
    800009cc:	9f99                	subw	a5,a5,a4
    800009ce:	00092703          	lw	a4,0(s2)
    800009d2:	fcf70de3          	beq	a4,a5,800009ac <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009d6:	00011917          	auipc	s2,0x11
    800009da:	f2290913          	addi	s2,s2,-222 # 800118f8 <uart_tx_lock>
    800009de:	96ca                	add	a3,a3,s2
    800009e0:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009e4:	00008717          	auipc	a4,0x8
    800009e8:	62f72223          	sw	a5,1572(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	ec2080e7          	jalr	-318(ra) # 800008ae <uartstart>
      release(&uart_tx_lock);
    800009f4:	854a                	mv	a0,s2
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	330080e7          	jalr	816(ra) # 80000d26 <release>
}
    800009fe:	70a2                	ld	ra,40(sp)
    80000a00:	7402                	ld	s0,32(sp)
    80000a02:	64e2                	ld	s1,24(sp)
    80000a04:	6942                	ld	s2,16(sp)
    80000a06:	69a2                	ld	s3,8(sp)
    80000a08:	6a02                	ld	s4,0(sp)
    80000a0a:	6145                	addi	sp,sp,48
    80000a0c:	8082                	ret

0000000080000a0e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a0e:	1141                	addi	sp,sp,-16
    80000a10:	e422                	sd	s0,8(sp)
    80000a12:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a14:	100007b7          	lui	a5,0x10000
    80000a18:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a1c:	8b85                	andi	a5,a5,1
    80000a1e:	cb91                	beqz	a5,80000a32 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a20:	100007b7          	lui	a5,0x10000
    80000a24:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a28:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a2c:	6422                	ld	s0,8(sp)
    80000a2e:	0141                	addi	sp,sp,16
    80000a30:	8082                	ret
    return -1;
    80000a32:	557d                	li	a0,-1
    80000a34:	bfe5                	j	80000a2c <uartgetc+0x1e>

0000000080000a36 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a36:	1101                	addi	sp,sp,-32
    80000a38:	ec06                	sd	ra,24(sp)
    80000a3a:	e822                	sd	s0,16(sp)
    80000a3c:	e426                	sd	s1,8(sp)
    80000a3e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a40:	54fd                	li	s1,-1
    80000a42:	a029                	j	80000a4c <uartintr+0x16>
      break;
    consoleintr(c);
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	87e080e7          	jalr	-1922(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	fc2080e7          	jalr	-62(ra) # 80000a0e <uartgetc>
    if(c == -1)
    80000a54:	fe9518e3          	bne	a0,s1,80000a44 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a58:	00011497          	auipc	s1,0x11
    80000a5c:	ea048493          	addi	s1,s1,-352 # 800118f8 <uart_tx_lock>
    80000a60:	8526                	mv	a0,s1
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	210080e7          	jalr	528(ra) # 80000c72 <acquire>
  uartstart();
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	e44080e7          	jalr	-444(ra) # 800008ae <uartstart>
  release(&uart_tx_lock);
    80000a72:	8526                	mv	a0,s1
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	2b2080e7          	jalr	690(ra) # 80000d26 <release>
}
    80000a7c:	60e2                	ld	ra,24(sp)
    80000a7e:	6442                	ld	s0,16(sp)
    80000a80:	64a2                	ld	s1,8(sp)
    80000a82:	6105                	addi	sp,sp,32
    80000a84:	8082                	ret

0000000080000a86 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a86:	1101                	addi	sp,sp,-32
    80000a88:	ec06                	sd	ra,24(sp)
    80000a8a:	e822                	sd	s0,16(sp)
    80000a8c:	e426                	sd	s1,8(sp)
    80000a8e:	e04a                	sd	s2,0(sp)
    80000a90:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a92:	03451793          	slli	a5,a0,0x34
    80000a96:	ebb9                	bnez	a5,80000aec <kfree+0x66>
    80000a98:	84aa                	mv	s1,a0
    80000a9a:	00026797          	auipc	a5,0x26
    80000a9e:	56678793          	addi	a5,a5,1382 # 80027000 <end>
    80000aa2:	04f56563          	bltu	a0,a5,80000aec <kfree+0x66>
    80000aa6:	47c5                	li	a5,17
    80000aa8:	07ee                	slli	a5,a5,0x1b
    80000aaa:	04f57163          	bgeu	a0,a5,80000aec <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000aae:	6605                	lui	a2,0x1
    80000ab0:	4585                	li	a1,1
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	2bc080e7          	jalr	700(ra) # 80000d6e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aba:	00011917          	auipc	s2,0x11
    80000abe:	e7690913          	addi	s2,s2,-394 # 80011930 <kmem>
    80000ac2:	854a                	mv	a0,s2
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	1ae080e7          	jalr	430(ra) # 80000c72 <acquire>
  r->next = kmem.freelist;
    80000acc:	01893783          	ld	a5,24(s2)
    80000ad0:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ad2:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ad6:	854a                	mv	a0,s2
    80000ad8:	00000097          	auipc	ra,0x0
    80000adc:	24e080e7          	jalr	590(ra) # 80000d26 <release>
}
    80000ae0:	60e2                	ld	ra,24(sp)
    80000ae2:	6442                	ld	s0,16(sp)
    80000ae4:	64a2                	ld	s1,8(sp)
    80000ae6:	6902                	ld	s2,0(sp)
    80000ae8:	6105                	addi	sp,sp,32
    80000aea:	8082                	ret
    panic("kfree");
    80000aec:	00007517          	auipc	a0,0x7
    80000af0:	58c50513          	addi	a0,a0,1420 # 80008078 <digits+0x20>
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	aec080e7          	jalr	-1300(ra) # 800005e0 <panic>

0000000080000afc <freerange>:
{
    80000afc:	7179                	addi	sp,sp,-48
    80000afe:	f406                	sd	ra,40(sp)
    80000b00:	f022                	sd	s0,32(sp)
    80000b02:	ec26                	sd	s1,24(sp)
    80000b04:	e84a                	sd	s2,16(sp)
    80000b06:	e44e                	sd	s3,8(sp)
    80000b08:	e052                	sd	s4,0(sp)
    80000b0a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b0c:	6785                	lui	a5,0x1
    80000b0e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b12:	94aa                	add	s1,s1,a0
    80000b14:	757d                	lui	a0,0xfffff
    80000b16:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b18:	94be                	add	s1,s1,a5
    80000b1a:	0095ee63          	bltu	a1,s1,80000b36 <freerange+0x3a>
    80000b1e:	892e                	mv	s2,a1
    kfree(p);
    80000b20:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b22:	6985                	lui	s3,0x1
    kfree(p);
    80000b24:	01448533          	add	a0,s1,s4
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	f5e080e7          	jalr	-162(ra) # 80000a86 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b30:	94ce                	add	s1,s1,s3
    80000b32:	fe9979e3          	bgeu	s2,s1,80000b24 <freerange+0x28>
}
    80000b36:	70a2                	ld	ra,40(sp)
    80000b38:	7402                	ld	s0,32(sp)
    80000b3a:	64e2                	ld	s1,24(sp)
    80000b3c:	6942                	ld	s2,16(sp)
    80000b3e:	69a2                	ld	s3,8(sp)
    80000b40:	6a02                	ld	s4,0(sp)
    80000b42:	6145                	addi	sp,sp,48
    80000b44:	8082                	ret

0000000080000b46 <kinit>:
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e406                	sd	ra,8(sp)
    80000b4a:	e022                	sd	s0,0(sp)
    80000b4c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b4e:	00007597          	auipc	a1,0x7
    80000b52:	53258593          	addi	a1,a1,1330 # 80008080 <digits+0x28>
    80000b56:	00011517          	auipc	a0,0x11
    80000b5a:	dda50513          	addi	a0,a0,-550 # 80011930 <kmem>
    80000b5e:	00000097          	auipc	ra,0x0
    80000b62:	084080e7          	jalr	132(ra) # 80000be2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b66:	45c5                	li	a1,17
    80000b68:	05ee                	slli	a1,a1,0x1b
    80000b6a:	00026517          	auipc	a0,0x26
    80000b6e:	49650513          	addi	a0,a0,1174 # 80027000 <end>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	f8a080e7          	jalr	-118(ra) # 80000afc <freerange>
}
    80000b7a:	60a2                	ld	ra,8(sp)
    80000b7c:	6402                	ld	s0,0(sp)
    80000b7e:	0141                	addi	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b82:	1101                	addi	sp,sp,-32
    80000b84:	ec06                	sd	ra,24(sp)
    80000b86:	e822                	sd	s0,16(sp)
    80000b88:	e426                	sd	s1,8(sp)
    80000b8a:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b8c:	00011497          	auipc	s1,0x11
    80000b90:	da448493          	addi	s1,s1,-604 # 80011930 <kmem>
    80000b94:	8526                	mv	a0,s1
    80000b96:	00000097          	auipc	ra,0x0
    80000b9a:	0dc080e7          	jalr	220(ra) # 80000c72 <acquire>
  r = kmem.freelist;
    80000b9e:	6c84                	ld	s1,24(s1)
  if(r)
    80000ba0:	c885                	beqz	s1,80000bd0 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000ba2:	609c                	ld	a5,0(s1)
    80000ba4:	00011517          	auipc	a0,0x11
    80000ba8:	d8c50513          	addi	a0,a0,-628 # 80011930 <kmem>
    80000bac:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	178080e7          	jalr	376(ra) # 80000d26 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bb6:	6605                	lui	a2,0x1
    80000bb8:	4595                	li	a1,5
    80000bba:	8526                	mv	a0,s1
    80000bbc:	00000097          	auipc	ra,0x0
    80000bc0:	1b2080e7          	jalr	434(ra) # 80000d6e <memset>
  return (void*)r;
}
    80000bc4:	8526                	mv	a0,s1
    80000bc6:	60e2                	ld	ra,24(sp)
    80000bc8:	6442                	ld	s0,16(sp)
    80000bca:	64a2                	ld	s1,8(sp)
    80000bcc:	6105                	addi	sp,sp,32
    80000bce:	8082                	ret
  release(&kmem.lock);
    80000bd0:	00011517          	auipc	a0,0x11
    80000bd4:	d6050513          	addi	a0,a0,-672 # 80011930 <kmem>
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	14e080e7          	jalr	334(ra) # 80000d26 <release>
  if(r)
    80000be0:	b7d5                	j	80000bc4 <kalloc+0x42>

0000000080000be2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000be2:	1141                	addi	sp,sp,-16
    80000be4:	e422                	sd	s0,8(sp)
    80000be6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000be8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bea:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bee:	00053823          	sd	zero,16(a0)
}
    80000bf2:	6422                	ld	s0,8(sp)
    80000bf4:	0141                	addi	sp,sp,16
    80000bf6:	8082                	ret

0000000080000bf8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bf8:	411c                	lw	a5,0(a0)
    80000bfa:	e399                	bnez	a5,80000c00 <holding+0x8>
    80000bfc:	4501                	li	a0,0
  return r;
}
    80000bfe:	8082                	ret
{
    80000c00:	1101                	addi	sp,sp,-32
    80000c02:	ec06                	sd	ra,24(sp)
    80000c04:	e822                	sd	s0,16(sp)
    80000c06:	e426                	sd	s1,8(sp)
    80000c08:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c0a:	6904                	ld	s1,16(a0)
    80000c0c:	00001097          	auipc	ra,0x1
    80000c10:	e16080e7          	jalr	-490(ra) # 80001a22 <mycpu>
    80000c14:	40a48533          	sub	a0,s1,a0
    80000c18:	00153513          	seqz	a0,a0
}
    80000c1c:	60e2                	ld	ra,24(sp)
    80000c1e:	6442                	ld	s0,16(sp)
    80000c20:	64a2                	ld	s1,8(sp)
    80000c22:	6105                	addi	sp,sp,32
    80000c24:	8082                	ret

0000000080000c26 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c26:	1101                	addi	sp,sp,-32
    80000c28:	ec06                	sd	ra,24(sp)
    80000c2a:	e822                	sd	s0,16(sp)
    80000c2c:	e426                	sd	s1,8(sp)
    80000c2e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c30:	100024f3          	csrr	s1,sstatus
    80000c34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c3a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c3e:	00001097          	auipc	ra,0x1
    80000c42:	de4080e7          	jalr	-540(ra) # 80001a22 <mycpu>
    80000c46:	5d3c                	lw	a5,120(a0)
    80000c48:	cf89                	beqz	a5,80000c62 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dd8080e7          	jalr	-552(ra) # 80001a22 <mycpu>
    80000c52:	5d3c                	lw	a5,120(a0)
    80000c54:	2785                	addiw	a5,a5,1
    80000c56:	dd3c                	sw	a5,120(a0)
}
    80000c58:	60e2                	ld	ra,24(sp)
    80000c5a:	6442                	ld	s0,16(sp)
    80000c5c:	64a2                	ld	s1,8(sp)
    80000c5e:	6105                	addi	sp,sp,32
    80000c60:	8082                	ret
    mycpu()->intena = old;
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	dc0080e7          	jalr	-576(ra) # 80001a22 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c6a:	8085                	srli	s1,s1,0x1
    80000c6c:	8885                	andi	s1,s1,1
    80000c6e:	dd64                	sw	s1,124(a0)
    80000c70:	bfe9                	j	80000c4a <push_off+0x24>

0000000080000c72 <acquire>:
{
    80000c72:	1101                	addi	sp,sp,-32
    80000c74:	ec06                	sd	ra,24(sp)
    80000c76:	e822                	sd	s0,16(sp)
    80000c78:	e426                	sd	s1,8(sp)
    80000c7a:	1000                	addi	s0,sp,32
    80000c7c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	fa8080e7          	jalr	-88(ra) # 80000c26 <push_off>
  if(holding(lk))
    80000c86:	8526                	mv	a0,s1
    80000c88:	00000097          	auipc	ra,0x0
    80000c8c:	f70080e7          	jalr	-144(ra) # 80000bf8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c90:	4705                	li	a4,1
  if(holding(lk))
    80000c92:	e115                	bnez	a0,80000cb6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c94:	87ba                	mv	a5,a4
    80000c96:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c9a:	2781                	sext.w	a5,a5
    80000c9c:	ffe5                	bnez	a5,80000c94 <acquire+0x22>
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ca2:	00001097          	auipc	ra,0x1
    80000ca6:	d80080e7          	jalr	-640(ra) # 80001a22 <mycpu>
    80000caa:	e888                	sd	a0,16(s1)
}
    80000cac:	60e2                	ld	ra,24(sp)
    80000cae:	6442                	ld	s0,16(sp)
    80000cb0:	64a2                	ld	s1,8(sp)
    80000cb2:	6105                	addi	sp,sp,32
    80000cb4:	8082                	ret
    panic("acquire");
    80000cb6:	00007517          	auipc	a0,0x7
    80000cba:	3d250513          	addi	a0,a0,978 # 80008088 <digits+0x30>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	922080e7          	jalr	-1758(ra) # 800005e0 <panic>

0000000080000cc6 <pop_off>:

void
pop_off(void)
{
    80000cc6:	1141                	addi	sp,sp,-16
    80000cc8:	e406                	sd	ra,8(sp)
    80000cca:	e022                	sd	s0,0(sp)
    80000ccc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cce:	00001097          	auipc	ra,0x1
    80000cd2:	d54080e7          	jalr	-684(ra) # 80001a22 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cda:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cdc:	e78d                	bnez	a5,80000d06 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cde:	5d3c                	lw	a5,120(a0)
    80000ce0:	02f05b63          	blez	a5,80000d16 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ce4:	37fd                	addiw	a5,a5,-1
    80000ce6:	0007871b          	sext.w	a4,a5
    80000cea:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cec:	eb09                	bnez	a4,80000cfe <pop_off+0x38>
    80000cee:	5d7c                	lw	a5,124(a0)
    80000cf0:	c799                	beqz	a5,80000cfe <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cf2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cf6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cfa:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cfe:	60a2                	ld	ra,8(sp)
    80000d00:	6402                	ld	s0,0(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret
    panic("pop_off - interruptible");
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	38a50513          	addi	a0,a0,906 # 80008090 <digits+0x38>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	8d2080e7          	jalr	-1838(ra) # 800005e0 <panic>
    panic("pop_off");
    80000d16:	00007517          	auipc	a0,0x7
    80000d1a:	39250513          	addi	a0,a0,914 # 800080a8 <digits+0x50>
    80000d1e:	00000097          	auipc	ra,0x0
    80000d22:	8c2080e7          	jalr	-1854(ra) # 800005e0 <panic>

0000000080000d26 <release>:
{
    80000d26:	1101                	addi	sp,sp,-32
    80000d28:	ec06                	sd	ra,24(sp)
    80000d2a:	e822                	sd	s0,16(sp)
    80000d2c:	e426                	sd	s1,8(sp)
    80000d2e:	1000                	addi	s0,sp,32
    80000d30:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	ec6080e7          	jalr	-314(ra) # 80000bf8 <holding>
    80000d3a:	c115                	beqz	a0,80000d5e <release+0x38>
  lk->cpu = 0;
    80000d3c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d40:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d44:	0f50000f          	fence	iorw,ow
    80000d48:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d4c:	00000097          	auipc	ra,0x0
    80000d50:	f7a080e7          	jalr	-134(ra) # 80000cc6 <pop_off>
}
    80000d54:	60e2                	ld	ra,24(sp)
    80000d56:	6442                	ld	s0,16(sp)
    80000d58:	64a2                	ld	s1,8(sp)
    80000d5a:	6105                	addi	sp,sp,32
    80000d5c:	8082                	ret
    panic("release");
    80000d5e:	00007517          	auipc	a0,0x7
    80000d62:	35250513          	addi	a0,a0,850 # 800080b0 <digits+0x58>
    80000d66:	00000097          	auipc	ra,0x0
    80000d6a:	87a080e7          	jalr	-1926(ra) # 800005e0 <panic>

0000000080000d6e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d74:	ca19                	beqz	a2,80000d8a <memset+0x1c>
    80000d76:	87aa                	mv	a5,a0
    80000d78:	1602                	slli	a2,a2,0x20
    80000d7a:	9201                	srli	a2,a2,0x20
    80000d7c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d80:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d84:	0785                	addi	a5,a5,1
    80000d86:	fee79de3          	bne	a5,a4,80000d80 <memset+0x12>
  }
  return dst;
}
    80000d8a:	6422                	ld	s0,8(sp)
    80000d8c:	0141                	addi	sp,sp,16
    80000d8e:	8082                	ret

0000000080000d90 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d96:	ca05                	beqz	a2,80000dc6 <memcmp+0x36>
    80000d98:	fff6069b          	addiw	a3,a2,-1
    80000d9c:	1682                	slli	a3,a3,0x20
    80000d9e:	9281                	srli	a3,a3,0x20
    80000da0:	0685                	addi	a3,a3,1
    80000da2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	0005c703          	lbu	a4,0(a1)
    80000dac:	00e79863          	bne	a5,a4,80000dbc <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000db0:	0505                	addi	a0,a0,1
    80000db2:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000db4:	fed518e3          	bne	a0,a3,80000da4 <memcmp+0x14>
  }

  return 0;
    80000db8:	4501                	li	a0,0
    80000dba:	a019                	j	80000dc0 <memcmp+0x30>
      return *s1 - *s2;
    80000dbc:	40e7853b          	subw	a0,a5,a4
}
    80000dc0:	6422                	ld	s0,8(sp)
    80000dc2:	0141                	addi	sp,sp,16
    80000dc4:	8082                	ret
  return 0;
    80000dc6:	4501                	li	a0,0
    80000dc8:	bfe5                	j	80000dc0 <memcmp+0x30>

0000000080000dca <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dca:	1141                	addi	sp,sp,-16
    80000dcc:	e422                	sd	s0,8(sp)
    80000dce:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dd0:	02a5e563          	bltu	a1,a0,80000dfa <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dd4:	fff6069b          	addiw	a3,a2,-1
    80000dd8:	ce11                	beqz	a2,80000df4 <memmove+0x2a>
    80000dda:	1682                	slli	a3,a3,0x20
    80000ddc:	9281                	srli	a3,a3,0x20
    80000dde:	0685                	addi	a3,a3,1
    80000de0:	96ae                	add	a3,a3,a1
    80000de2:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000de4:	0585                	addi	a1,a1,1
    80000de6:	0785                	addi	a5,a5,1
    80000de8:	fff5c703          	lbu	a4,-1(a1)
    80000dec:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000df0:	fed59ae3          	bne	a1,a3,80000de4 <memmove+0x1a>

  return dst;
}
    80000df4:	6422                	ld	s0,8(sp)
    80000df6:	0141                	addi	sp,sp,16
    80000df8:	8082                	ret
  if(s < d && s + n > d){
    80000dfa:	02061713          	slli	a4,a2,0x20
    80000dfe:	9301                	srli	a4,a4,0x20
    80000e00:	00e587b3          	add	a5,a1,a4
    80000e04:	fcf578e3          	bgeu	a0,a5,80000dd4 <memmove+0xa>
    d += n;
    80000e08:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	d27d                	beqz	a2,80000df4 <memmove+0x2a>
    80000e10:	02069613          	slli	a2,a3,0x20
    80000e14:	9201                	srli	a2,a2,0x20
    80000e16:	fff64613          	not	a2,a2
    80000e1a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e1c:	17fd                	addi	a5,a5,-1
    80000e1e:	177d                	addi	a4,a4,-1
    80000e20:	0007c683          	lbu	a3,0(a5)
    80000e24:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e28:	fef61ae3          	bne	a2,a5,80000e1c <memmove+0x52>
    80000e2c:	b7e1                	j	80000df4 <memmove+0x2a>

0000000080000e2e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e2e:	1141                	addi	sp,sp,-16
    80000e30:	e406                	sd	ra,8(sp)
    80000e32:	e022                	sd	s0,0(sp)
    80000e34:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e36:	00000097          	auipc	ra,0x0
    80000e3a:	f94080e7          	jalr	-108(ra) # 80000dca <memmove>
}
    80000e3e:	60a2                	ld	ra,8(sp)
    80000e40:	6402                	ld	s0,0(sp)
    80000e42:	0141                	addi	sp,sp,16
    80000e44:	8082                	ret

0000000080000e46 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e46:	1141                	addi	sp,sp,-16
    80000e48:	e422                	sd	s0,8(sp)
    80000e4a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e4c:	ce11                	beqz	a2,80000e68 <strncmp+0x22>
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf89                	beqz	a5,80000e6c <strncmp+0x26>
    80000e54:	0005c703          	lbu	a4,0(a1)
    80000e58:	00f71a63          	bne	a4,a5,80000e6c <strncmp+0x26>
    n--, p++, q++;
    80000e5c:	367d                	addiw	a2,a2,-1
    80000e5e:	0505                	addi	a0,a0,1
    80000e60:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e62:	f675                	bnez	a2,80000e4e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e64:	4501                	li	a0,0
    80000e66:	a809                	j	80000e78 <strncmp+0x32>
    80000e68:	4501                	li	a0,0
    80000e6a:	a039                	j	80000e78 <strncmp+0x32>
  if(n == 0)
    80000e6c:	ca09                	beqz	a2,80000e7e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e6e:	00054503          	lbu	a0,0(a0)
    80000e72:	0005c783          	lbu	a5,0(a1)
    80000e76:	9d1d                	subw	a0,a0,a5
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret
    return 0;
    80000e7e:	4501                	li	a0,0
    80000e80:	bfe5                	j	80000e78 <strncmp+0x32>

0000000080000e82 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e422                	sd	s0,8(sp)
    80000e86:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e88:	872a                	mv	a4,a0
    80000e8a:	8832                	mv	a6,a2
    80000e8c:	367d                	addiw	a2,a2,-1
    80000e8e:	01005963          	blez	a6,80000ea0 <strncpy+0x1e>
    80000e92:	0705                	addi	a4,a4,1
    80000e94:	0005c783          	lbu	a5,0(a1)
    80000e98:	fef70fa3          	sb	a5,-1(a4)
    80000e9c:	0585                	addi	a1,a1,1
    80000e9e:	f7f5                	bnez	a5,80000e8a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ea0:	86ba                	mv	a3,a4
    80000ea2:	00c05c63          	blez	a2,80000eba <strncpy+0x38>
    *s++ = 0;
    80000ea6:	0685                	addi	a3,a3,1
    80000ea8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eac:	fff6c793          	not	a5,a3
    80000eb0:	9fb9                	addw	a5,a5,a4
    80000eb2:	010787bb          	addw	a5,a5,a6
    80000eb6:	fef048e3          	bgtz	a5,80000ea6 <strncpy+0x24>
  return os;
}
    80000eba:	6422                	ld	s0,8(sp)
    80000ebc:	0141                	addi	sp,sp,16
    80000ebe:	8082                	ret

0000000080000ec0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ec0:	1141                	addi	sp,sp,-16
    80000ec2:	e422                	sd	s0,8(sp)
    80000ec4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ec6:	02c05363          	blez	a2,80000eec <safestrcpy+0x2c>
    80000eca:	fff6069b          	addiw	a3,a2,-1
    80000ece:	1682                	slli	a3,a3,0x20
    80000ed0:	9281                	srli	a3,a3,0x20
    80000ed2:	96ae                	add	a3,a3,a1
    80000ed4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ed6:	00d58963          	beq	a1,a3,80000ee8 <safestrcpy+0x28>
    80000eda:	0585                	addi	a1,a1,1
    80000edc:	0785                	addi	a5,a5,1
    80000ede:	fff5c703          	lbu	a4,-1(a1)
    80000ee2:	fee78fa3          	sb	a4,-1(a5)
    80000ee6:	fb65                	bnez	a4,80000ed6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ee8:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eec:	6422                	ld	s0,8(sp)
    80000eee:	0141                	addi	sp,sp,16
    80000ef0:	8082                	ret

0000000080000ef2 <strlen>:

int
strlen(const char *s)
{
    80000ef2:	1141                	addi	sp,sp,-16
    80000ef4:	e422                	sd	s0,8(sp)
    80000ef6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ef8:	00054783          	lbu	a5,0(a0)
    80000efc:	cf91                	beqz	a5,80000f18 <strlen+0x26>
    80000efe:	0505                	addi	a0,a0,1
    80000f00:	87aa                	mv	a5,a0
    80000f02:	4685                	li	a3,1
    80000f04:	9e89                	subw	a3,a3,a0
    80000f06:	00f6853b          	addw	a0,a3,a5
    80000f0a:	0785                	addi	a5,a5,1
    80000f0c:	fff7c703          	lbu	a4,-1(a5)
    80000f10:	fb7d                	bnez	a4,80000f06 <strlen+0x14>
    ;
  return n;
}
    80000f12:	6422                	ld	s0,8(sp)
    80000f14:	0141                	addi	sp,sp,16
    80000f16:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f18:	4501                	li	a0,0
    80000f1a:	bfe5                	j	80000f12 <strlen+0x20>

0000000080000f1c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f1c:	1141                	addi	sp,sp,-16
    80000f1e:	e406                	sd	ra,8(sp)
    80000f20:	e022                	sd	s0,0(sp)
    80000f22:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f24:	00001097          	auipc	ra,0x1
    80000f28:	aee080e7          	jalr	-1298(ra) # 80001a12 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f2c:	00008717          	auipc	a4,0x8
    80000f30:	0e070713          	addi	a4,a4,224 # 8000900c <started>
  if(cpuid() == 0){
    80000f34:	c139                	beqz	a0,80000f7a <main+0x5e>
    while(started == 0)
    80000f36:	431c                	lw	a5,0(a4)
    80000f38:	2781                	sext.w	a5,a5
    80000f3a:	dff5                	beqz	a5,80000f36 <main+0x1a>
      ;
    __sync_synchronize();
    80000f3c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f40:	00001097          	auipc	ra,0x1
    80000f44:	ad2080e7          	jalr	-1326(ra) # 80001a12 <cpuid>
    80000f48:	85aa                	mv	a1,a0
    80000f4a:	00007517          	auipc	a0,0x7
    80000f4e:	18650513          	addi	a0,a0,390 # 800080d0 <digits+0x78>
    80000f52:	fffff097          	auipc	ra,0xfffff
    80000f56:	6e0080e7          	jalr	1760(ra) # 80000632 <printf>
    kvminithart();    // turn on paging
    80000f5a:	00000097          	auipc	ra,0x0
    80000f5e:	0d8080e7          	jalr	216(ra) # 80001032 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f62:	00001097          	auipc	ra,0x1
    80000f66:	76e080e7          	jalr	1902(ra) # 800026d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e36080e7          	jalr	-458(ra) # 80005da0 <plicinithart>
  }

  scheduler();        
    80000f72:	00001097          	auipc	ra,0x1
    80000f76:	03c080e7          	jalr	60(ra) # 80001fae <scheduler>
    consoleinit();
    80000f7a:	fffff097          	auipc	ra,0xfffff
    80000f7e:	4da080e7          	jalr	1242(ra) # 80000454 <consoleinit>
    printfinit();
    80000f82:	fffff097          	auipc	ra,0xfffff
    80000f86:	5c0080e7          	jalr	1472(ra) # 80000542 <printfinit>
    printf("\n");
    80000f8a:	00007517          	auipc	a0,0x7
    80000f8e:	15650513          	addi	a0,a0,342 # 800080e0 <digits+0x88>
    80000f92:	fffff097          	auipc	ra,0xfffff
    80000f96:	6a0080e7          	jalr	1696(ra) # 80000632 <printf>
    printf("xv6 kernel is booting\n");
    80000f9a:	00007517          	auipc	a0,0x7
    80000f9e:	11e50513          	addi	a0,a0,286 # 800080b8 <digits+0x60>
    80000fa2:	fffff097          	auipc	ra,0xfffff
    80000fa6:	690080e7          	jalr	1680(ra) # 80000632 <printf>
    printf("\n");
    80000faa:	00007517          	auipc	a0,0x7
    80000fae:	13650513          	addi	a0,a0,310 # 800080e0 <digits+0x88>
    80000fb2:	fffff097          	auipc	ra,0xfffff
    80000fb6:	680080e7          	jalr	1664(ra) # 80000632 <printf>
    kinit();         // physical page allocator
    80000fba:	00000097          	auipc	ra,0x0
    80000fbe:	b8c080e7          	jalr	-1140(ra) # 80000b46 <kinit>
    kvminit();       // create kernel page table
    80000fc2:	00000097          	auipc	ra,0x0
    80000fc6:	2a0080e7          	jalr	672(ra) # 80001262 <kvminit>
    kvminithart();   // turn on paging
    80000fca:	00000097          	auipc	ra,0x0
    80000fce:	068080e7          	jalr	104(ra) # 80001032 <kvminithart>
    procinit();      // process table
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	970080e7          	jalr	-1680(ra) # 80001942 <procinit>
    trapinit();      // trap vectors
    80000fda:	00001097          	auipc	ra,0x1
    80000fde:	6ce080e7          	jalr	1742(ra) # 800026a8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe2:	00001097          	auipc	ra,0x1
    80000fe6:	6ee080e7          	jalr	1774(ra) # 800026d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fea:	00005097          	auipc	ra,0x5
    80000fee:	da0080e7          	jalr	-608(ra) # 80005d8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ff2:	00005097          	auipc	ra,0x5
    80000ff6:	dae080e7          	jalr	-594(ra) # 80005da0 <plicinithart>
    binit();         // buffer cache
    80000ffa:	00002097          	auipc	ra,0x2
    80000ffe:	f58080e7          	jalr	-168(ra) # 80002f52 <binit>
    iinit();         // inode cache
    80001002:	00002097          	auipc	ra,0x2
    80001006:	5e8080e7          	jalr	1512(ra) # 800035ea <iinit>
    fileinit();      // file table
    8000100a:	00003097          	auipc	ra,0x3
    8000100e:	582080e7          	jalr	1410(ra) # 8000458c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001012:	00005097          	auipc	ra,0x5
    80001016:	e96080e7          	jalr	-362(ra) # 80005ea8 <virtio_disk_init>
    userinit();      // first user process
    8000101a:	00001097          	auipc	ra,0x1
    8000101e:	d2a080e7          	jalr	-726(ra) # 80001d44 <userinit>
    __sync_synchronize();
    80001022:	0ff0000f          	fence
    started = 1;
    80001026:	4785                	li	a5,1
    80001028:	00008717          	auipc	a4,0x8
    8000102c:	fef72223          	sw	a5,-28(a4) # 8000900c <started>
    80001030:	b789                	j	80000f72 <main+0x56>

0000000080001032 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001032:	1141                	addi	sp,sp,-16
    80001034:	e422                	sd	s0,8(sp)
    80001036:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001038:	00008797          	auipc	a5,0x8
    8000103c:	fd87b783          	ld	a5,-40(a5) # 80009010 <kernel_pagetable>
    80001040:	83b1                	srli	a5,a5,0xc
    80001042:	577d                	li	a4,-1
    80001044:	177e                	slli	a4,a4,0x3f
    80001046:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001048:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000104c:	12000073          	sfence.vma
  sfence_vma();
}
    80001050:	6422                	ld	s0,8(sp)
    80001052:	0141                	addi	sp,sp,16
    80001054:	8082                	ret

0000000080001056 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001056:	7139                	addi	sp,sp,-64
    80001058:	fc06                	sd	ra,56(sp)
    8000105a:	f822                	sd	s0,48(sp)
    8000105c:	f426                	sd	s1,40(sp)
    8000105e:	f04a                	sd	s2,32(sp)
    80001060:	ec4e                	sd	s3,24(sp)
    80001062:	e852                	sd	s4,16(sp)
    80001064:	e456                	sd	s5,8(sp)
    80001066:	e05a                	sd	s6,0(sp)
    80001068:	0080                	addi	s0,sp,64
    8000106a:	84aa                	mv	s1,a0
    8000106c:	89ae                	mv	s3,a1
    8000106e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001070:	57fd                	li	a5,-1
    80001072:	83e9                	srli	a5,a5,0x1a
    80001074:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001076:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001078:	04b7f263          	bgeu	a5,a1,800010bc <walk+0x66>
    panic("walk");
    8000107c:	00007517          	auipc	a0,0x7
    80001080:	06c50513          	addi	a0,a0,108 # 800080e8 <digits+0x90>
    80001084:	fffff097          	auipc	ra,0xfffff
    80001088:	55c080e7          	jalr	1372(ra) # 800005e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000108c:	060a8663          	beqz	s5,800010f8 <walk+0xa2>
    80001090:	00000097          	auipc	ra,0x0
    80001094:	af2080e7          	jalr	-1294(ra) # 80000b82 <kalloc>
    80001098:	84aa                	mv	s1,a0
    8000109a:	c529                	beqz	a0,800010e4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000109c:	6605                	lui	a2,0x1
    8000109e:	4581                	li	a1,0
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	cce080e7          	jalr	-818(ra) # 80000d6e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010a8:	00c4d793          	srli	a5,s1,0xc
    800010ac:	07aa                	slli	a5,a5,0xa
    800010ae:	0017e793          	ori	a5,a5,1
    800010b2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010b6:	3a5d                	addiw	s4,s4,-9
    800010b8:	036a0063          	beq	s4,s6,800010d8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010bc:	0149d933          	srl	s2,s3,s4
    800010c0:	1ff97913          	andi	s2,s2,511
    800010c4:	090e                	slli	s2,s2,0x3
    800010c6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010c8:	00093483          	ld	s1,0(s2)
    800010cc:	0014f793          	andi	a5,s1,1
    800010d0:	dfd5                	beqz	a5,8000108c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010d2:	80a9                	srli	s1,s1,0xa
    800010d4:	04b2                	slli	s1,s1,0xc
    800010d6:	b7c5                	j	800010b6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010d8:	00c9d513          	srli	a0,s3,0xc
    800010dc:	1ff57513          	andi	a0,a0,511
    800010e0:	050e                	slli	a0,a0,0x3
    800010e2:	9526                	add	a0,a0,s1
}
    800010e4:	70e2                	ld	ra,56(sp)
    800010e6:	7442                	ld	s0,48(sp)
    800010e8:	74a2                	ld	s1,40(sp)
    800010ea:	7902                	ld	s2,32(sp)
    800010ec:	69e2                	ld	s3,24(sp)
    800010ee:	6a42                	ld	s4,16(sp)
    800010f0:	6aa2                	ld	s5,8(sp)
    800010f2:	6b02                	ld	s6,0(sp)
    800010f4:	6121                	addi	sp,sp,64
    800010f6:	8082                	ret
        return 0;
    800010f8:	4501                	li	a0,0
    800010fa:	b7ed                	j	800010e4 <walk+0x8e>

00000000800010fc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010fc:	57fd                	li	a5,-1
    800010fe:	83e9                	srli	a5,a5,0x1a
    80001100:	00b7f463          	bgeu	a5,a1,80001108 <walkaddr+0xc>
    return 0;
    80001104:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001106:	8082                	ret
{
    80001108:	1141                	addi	sp,sp,-16
    8000110a:	e406                	sd	ra,8(sp)
    8000110c:	e022                	sd	s0,0(sp)
    8000110e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001110:	4601                	li	a2,0
    80001112:	00000097          	auipc	ra,0x0
    80001116:	f44080e7          	jalr	-188(ra) # 80001056 <walk>
  if(pte == 0)
    8000111a:	c105                	beqz	a0,8000113a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000111c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000111e:	0117f693          	andi	a3,a5,17
    80001122:	4745                	li	a4,17
    return 0;
    80001124:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001126:	00e68663          	beq	a3,a4,80001132 <walkaddr+0x36>
}
    8000112a:	60a2                	ld	ra,8(sp)
    8000112c:	6402                	ld	s0,0(sp)
    8000112e:	0141                	addi	sp,sp,16
    80001130:	8082                	ret
  pa = PTE2PA(*pte);
    80001132:	00a7d513          	srli	a0,a5,0xa
    80001136:	0532                	slli	a0,a0,0xc
  return pa;
    80001138:	bfcd                	j	8000112a <walkaddr+0x2e>
    return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7fd                	j	8000112a <walkaddr+0x2e>

000000008000113e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000113e:	1101                	addi	sp,sp,-32
    80001140:	ec06                	sd	ra,24(sp)
    80001142:	e822                	sd	s0,16(sp)
    80001144:	e426                	sd	s1,8(sp)
    80001146:	1000                	addi	s0,sp,32
    80001148:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000114a:	1552                	slli	a0,a0,0x34
    8000114c:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001150:	4601                	li	a2,0
    80001152:	00008517          	auipc	a0,0x8
    80001156:	ebe53503          	ld	a0,-322(a0) # 80009010 <kernel_pagetable>
    8000115a:	00000097          	auipc	ra,0x0
    8000115e:	efc080e7          	jalr	-260(ra) # 80001056 <walk>
  if(pte == 0)
    80001162:	cd09                	beqz	a0,8000117c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001164:	6108                	ld	a0,0(a0)
    80001166:	00157793          	andi	a5,a0,1
    8000116a:	c38d                	beqz	a5,8000118c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000116c:	8129                	srli	a0,a0,0xa
    8000116e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001170:	9526                	add	a0,a0,s1
    80001172:	60e2                	ld	ra,24(sp)
    80001174:	6442                	ld	s0,16(sp)
    80001176:	64a2                	ld	s1,8(sp)
    80001178:	6105                	addi	sp,sp,32
    8000117a:	8082                	ret
    panic("kvmpa");
    8000117c:	00007517          	auipc	a0,0x7
    80001180:	f7450513          	addi	a0,a0,-140 # 800080f0 <digits+0x98>
    80001184:	fffff097          	auipc	ra,0xfffff
    80001188:	45c080e7          	jalr	1116(ra) # 800005e0 <panic>
    panic("kvmpa");
    8000118c:	00007517          	auipc	a0,0x7
    80001190:	f6450513          	addi	a0,a0,-156 # 800080f0 <digits+0x98>
    80001194:	fffff097          	auipc	ra,0xfffff
    80001198:	44c080e7          	jalr	1100(ra) # 800005e0 <panic>

000000008000119c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000119c:	715d                	addi	sp,sp,-80
    8000119e:	e486                	sd	ra,72(sp)
    800011a0:	e0a2                	sd	s0,64(sp)
    800011a2:	fc26                	sd	s1,56(sp)
    800011a4:	f84a                	sd	s2,48(sp)
    800011a6:	f44e                	sd	s3,40(sp)
    800011a8:	f052                	sd	s4,32(sp)
    800011aa:	ec56                	sd	s5,24(sp)
    800011ac:	e85a                	sd	s6,16(sp)
    800011ae:	e45e                	sd	s7,8(sp)
    800011b0:	0880                	addi	s0,sp,80
    800011b2:	8aaa                	mv	s5,a0
    800011b4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011b6:	777d                	lui	a4,0xfffff
    800011b8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011bc:	167d                	addi	a2,a2,-1
    800011be:	00b609b3          	add	s3,a2,a1
    800011c2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011c6:	893e                	mv	s2,a5
    800011c8:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011cc:	6b85                	lui	s7,0x1
    800011ce:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011d2:	4605                	li	a2,1
    800011d4:	85ca                	mv	a1,s2
    800011d6:	8556                	mv	a0,s5
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	e7e080e7          	jalr	-386(ra) # 80001056 <walk>
    800011e0:	c51d                	beqz	a0,8000120e <mappages+0x72>
    if(*pte & PTE_V)
    800011e2:	611c                	ld	a5,0(a0)
    800011e4:	8b85                	andi	a5,a5,1
    800011e6:	ef81                	bnez	a5,800011fe <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011e8:	80b1                	srli	s1,s1,0xc
    800011ea:	04aa                	slli	s1,s1,0xa
    800011ec:	0164e4b3          	or	s1,s1,s6
    800011f0:	0014e493          	ori	s1,s1,1
    800011f4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011f6:	03390863          	beq	s2,s3,80001226 <mappages+0x8a>
    a += PGSIZE;
    800011fa:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011fc:	bfc9                	j	800011ce <mappages+0x32>
      panic("remap");
    800011fe:	00007517          	auipc	a0,0x7
    80001202:	efa50513          	addi	a0,a0,-262 # 800080f8 <digits+0xa0>
    80001206:	fffff097          	auipc	ra,0xfffff
    8000120a:	3da080e7          	jalr	986(ra) # 800005e0 <panic>
      return -1;
    8000120e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001210:	60a6                	ld	ra,72(sp)
    80001212:	6406                	ld	s0,64(sp)
    80001214:	74e2                	ld	s1,56(sp)
    80001216:	7942                	ld	s2,48(sp)
    80001218:	79a2                	ld	s3,40(sp)
    8000121a:	7a02                	ld	s4,32(sp)
    8000121c:	6ae2                	ld	s5,24(sp)
    8000121e:	6b42                	ld	s6,16(sp)
    80001220:	6ba2                	ld	s7,8(sp)
    80001222:	6161                	addi	sp,sp,80
    80001224:	8082                	ret
  return 0;
    80001226:	4501                	li	a0,0
    80001228:	b7e5                	j	80001210 <mappages+0x74>

000000008000122a <kvmmap>:
{
    8000122a:	1141                	addi	sp,sp,-16
    8000122c:	e406                	sd	ra,8(sp)
    8000122e:	e022                	sd	s0,0(sp)
    80001230:	0800                	addi	s0,sp,16
    80001232:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001234:	86ae                	mv	a3,a1
    80001236:	85aa                	mv	a1,a0
    80001238:	00008517          	auipc	a0,0x8
    8000123c:	dd853503          	ld	a0,-552(a0) # 80009010 <kernel_pagetable>
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f5c080e7          	jalr	-164(ra) # 8000119c <mappages>
    80001248:	e509                	bnez	a0,80001252 <kvmmap+0x28>
}
    8000124a:	60a2                	ld	ra,8(sp)
    8000124c:	6402                	ld	s0,0(sp)
    8000124e:	0141                	addi	sp,sp,16
    80001250:	8082                	ret
    panic("kvmmap");
    80001252:	00007517          	auipc	a0,0x7
    80001256:	eae50513          	addi	a0,a0,-338 # 80008100 <digits+0xa8>
    8000125a:	fffff097          	auipc	ra,0xfffff
    8000125e:	386080e7          	jalr	902(ra) # 800005e0 <panic>

0000000080001262 <kvminit>:
{
    80001262:	1101                	addi	sp,sp,-32
    80001264:	ec06                	sd	ra,24(sp)
    80001266:	e822                	sd	s0,16(sp)
    80001268:	e426                	sd	s1,8(sp)
    8000126a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	916080e7          	jalr	-1770(ra) # 80000b82 <kalloc>
    80001274:	00008797          	auipc	a5,0x8
    80001278:	d8a7be23          	sd	a0,-612(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000127c:	6605                	lui	a2,0x1
    8000127e:	4581                	li	a1,0
    80001280:	00000097          	auipc	ra,0x0
    80001284:	aee080e7          	jalr	-1298(ra) # 80000d6e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100005b7          	lui	a1,0x10000
    80001290:	10000537          	lui	a0,0x10000
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f96080e7          	jalr	-106(ra) # 8000122a <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6605                	lui	a2,0x1
    800012a0:	100015b7          	lui	a1,0x10001
    800012a4:	10001537          	lui	a0,0x10001
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f82080e7          	jalr	-126(ra) # 8000122a <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	6641                	lui	a2,0x10
    800012b4:	020005b7          	lui	a1,0x2000
    800012b8:	02000537          	lui	a0,0x2000
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	f6e080e7          	jalr	-146(ra) # 8000122a <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012c4:	4699                	li	a3,6
    800012c6:	00400637          	lui	a2,0x400
    800012ca:	0c0005b7          	lui	a1,0xc000
    800012ce:	0c000537          	lui	a0,0xc000
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f58080e7          	jalr	-168(ra) # 8000122a <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012da:	00007497          	auipc	s1,0x7
    800012de:	d2648493          	addi	s1,s1,-730 # 80008000 <etext>
    800012e2:	46a9                	li	a3,10
    800012e4:	80007617          	auipc	a2,0x80007
    800012e8:	d1c60613          	addi	a2,a2,-740 # 8000 <_entry-0x7fff8000>
    800012ec:	4585                	li	a1,1
    800012ee:	05fe                	slli	a1,a1,0x1f
    800012f0:	852e                	mv	a0,a1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f38080e7          	jalr	-200(ra) # 8000122a <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012fa:	4699                	li	a3,6
    800012fc:	4645                	li	a2,17
    800012fe:	066e                	slli	a2,a2,0x1b
    80001300:	8e05                	sub	a2,a2,s1
    80001302:	85a6                	mv	a1,s1
    80001304:	8526                	mv	a0,s1
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	f24080e7          	jalr	-220(ra) # 8000122a <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000130e:	46a9                	li	a3,10
    80001310:	6605                	lui	a2,0x1
    80001312:	00006597          	auipc	a1,0x6
    80001316:	cee58593          	addi	a1,a1,-786 # 80007000 <_trampoline>
    8000131a:	04000537          	lui	a0,0x4000
    8000131e:	157d                	addi	a0,a0,-1
    80001320:	0532                	slli	a0,a0,0xc
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f08080e7          	jalr	-248(ra) # 8000122a <kvmmap>
}
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001334:	715d                	addi	sp,sp,-80
    80001336:	e486                	sd	ra,72(sp)
    80001338:	e0a2                	sd	s0,64(sp)
    8000133a:	fc26                	sd	s1,56(sp)
    8000133c:	f84a                	sd	s2,48(sp)
    8000133e:	f44e                	sd	s3,40(sp)
    80001340:	f052                	sd	s4,32(sp)
    80001342:	ec56                	sd	s5,24(sp)
    80001344:	e85a                	sd	s6,16(sp)
    80001346:	e45e                	sd	s7,8(sp)
    80001348:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000134a:	03459793          	slli	a5,a1,0x34
    8000134e:	e795                	bnez	a5,8000137a <uvmunmap+0x46>
    80001350:	8a2a                	mv	s4,a0
    80001352:	892e                	mv	s2,a1
    80001354:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001356:	0632                	slli	a2,a2,0xc
    80001358:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135e:	6b05                	lui	s6,0x1
    80001360:	0735e263          	bltu	a1,s3,800013c4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001364:	60a6                	ld	ra,72(sp)
    80001366:	6406                	ld	s0,64(sp)
    80001368:	74e2                	ld	s1,56(sp)
    8000136a:	7942                	ld	s2,48(sp)
    8000136c:	79a2                	ld	s3,40(sp)
    8000136e:	7a02                	ld	s4,32(sp)
    80001370:	6ae2                	ld	s5,24(sp)
    80001372:	6b42                	ld	s6,16(sp)
    80001374:	6ba2                	ld	s7,8(sp)
    80001376:	6161                	addi	sp,sp,80
    80001378:	8082                	ret
    panic("uvmunmap: not aligned");
    8000137a:	00007517          	auipc	a0,0x7
    8000137e:	d8e50513          	addi	a0,a0,-626 # 80008108 <digits+0xb0>
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	25e080e7          	jalr	606(ra) # 800005e0 <panic>
      panic("uvmunmap: walk");
    8000138a:	00007517          	auipc	a0,0x7
    8000138e:	d9650513          	addi	a0,a0,-618 # 80008120 <digits+0xc8>
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	24e080e7          	jalr	590(ra) # 800005e0 <panic>
      panic("uvmunmap: not mapped");
    8000139a:	00007517          	auipc	a0,0x7
    8000139e:	d9650513          	addi	a0,a0,-618 # 80008130 <digits+0xd8>
    800013a2:	fffff097          	auipc	ra,0xfffff
    800013a6:	23e080e7          	jalr	574(ra) # 800005e0 <panic>
      panic("uvmunmap: not a leaf");
    800013aa:	00007517          	auipc	a0,0x7
    800013ae:	d9e50513          	addi	a0,a0,-610 # 80008148 <digits+0xf0>
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	22e080e7          	jalr	558(ra) # 800005e0 <panic>
    *pte = 0;
    800013ba:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013be:	995a                	add	s2,s2,s6
    800013c0:	fb3972e3          	bgeu	s2,s3,80001364 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013c4:	4601                	li	a2,0
    800013c6:	85ca                	mv	a1,s2
    800013c8:	8552                	mv	a0,s4
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	c8c080e7          	jalr	-884(ra) # 80001056 <walk>
    800013d2:	84aa                	mv	s1,a0
    800013d4:	d95d                	beqz	a0,8000138a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013d6:	6108                	ld	a0,0(a0)
    800013d8:	00157793          	andi	a5,a0,1
    800013dc:	dfdd                	beqz	a5,8000139a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013de:	3ff57793          	andi	a5,a0,1023
    800013e2:	fd7784e3          	beq	a5,s7,800013aa <uvmunmap+0x76>
    if(do_free){
    800013e6:	fc0a8ae3          	beqz	s5,800013ba <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013ea:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ec:	0532                	slli	a0,a0,0xc
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	698080e7          	jalr	1688(ra) # 80000a86 <kfree>
    800013f6:	b7d1                	j	800013ba <uvmunmap+0x86>

00000000800013f8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f8:	1101                	addi	sp,sp,-32
    800013fa:	ec06                	sd	ra,24(sp)
    800013fc:	e822                	sd	s0,16(sp)
    800013fe:	e426                	sd	s1,8(sp)
    80001400:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001402:	fffff097          	auipc	ra,0xfffff
    80001406:	780080e7          	jalr	1920(ra) # 80000b82 <kalloc>
    8000140a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000140c:	c519                	beqz	a0,8000141a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000140e:	6605                	lui	a2,0x1
    80001410:	4581                	li	a1,0
    80001412:	00000097          	auipc	ra,0x0
    80001416:	95c080e7          	jalr	-1700(ra) # 80000d6e <memset>
  return pagetable;
}
    8000141a:	8526                	mv	a0,s1
    8000141c:	60e2                	ld	ra,24(sp)
    8000141e:	6442                	ld	s0,16(sp)
    80001420:	64a2                	ld	s1,8(sp)
    80001422:	6105                	addi	sp,sp,32
    80001424:	8082                	ret

0000000080001426 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001426:	7179                	addi	sp,sp,-48
    80001428:	f406                	sd	ra,40(sp)
    8000142a:	f022                	sd	s0,32(sp)
    8000142c:	ec26                	sd	s1,24(sp)
    8000142e:	e84a                	sd	s2,16(sp)
    80001430:	e44e                	sd	s3,8(sp)
    80001432:	e052                	sd	s4,0(sp)
    80001434:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001436:	6785                	lui	a5,0x1
    80001438:	04f67863          	bgeu	a2,a5,80001488 <uvminit+0x62>
    8000143c:	8a2a                	mv	s4,a0
    8000143e:	89ae                	mv	s3,a1
    80001440:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	740080e7          	jalr	1856(ra) # 80000b82 <kalloc>
    8000144a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000144c:	6605                	lui	a2,0x1
    8000144e:	4581                	li	a1,0
    80001450:	00000097          	auipc	ra,0x0
    80001454:	91e080e7          	jalr	-1762(ra) # 80000d6e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001458:	4779                	li	a4,30
    8000145a:	86ca                	mv	a3,s2
    8000145c:	6605                	lui	a2,0x1
    8000145e:	4581                	li	a1,0
    80001460:	8552                	mv	a0,s4
    80001462:	00000097          	auipc	ra,0x0
    80001466:	d3a080e7          	jalr	-710(ra) # 8000119c <mappages>
  memmove(mem, src, sz);
    8000146a:	8626                	mv	a2,s1
    8000146c:	85ce                	mv	a1,s3
    8000146e:	854a                	mv	a0,s2
    80001470:	00000097          	auipc	ra,0x0
    80001474:	95a080e7          	jalr	-1702(ra) # 80000dca <memmove>
}
    80001478:	70a2                	ld	ra,40(sp)
    8000147a:	7402                	ld	s0,32(sp)
    8000147c:	64e2                	ld	s1,24(sp)
    8000147e:	6942                	ld	s2,16(sp)
    80001480:	69a2                	ld	s3,8(sp)
    80001482:	6a02                	ld	s4,0(sp)
    80001484:	6145                	addi	sp,sp,48
    80001486:	8082                	ret
    panic("inituvm: more than a page");
    80001488:	00007517          	auipc	a0,0x7
    8000148c:	cd850513          	addi	a0,a0,-808 # 80008160 <digits+0x108>
    80001490:	fffff097          	auipc	ra,0xfffff
    80001494:	150080e7          	jalr	336(ra) # 800005e0 <panic>

0000000080001498 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001498:	1101                	addi	sp,sp,-32
    8000149a:	ec06                	sd	ra,24(sp)
    8000149c:	e822                	sd	s0,16(sp)
    8000149e:	e426                	sd	s1,8(sp)
    800014a0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014a4:	00b67d63          	bgeu	a2,a1,800014be <uvmdealloc+0x26>
    800014a8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014aa:	6785                	lui	a5,0x1
    800014ac:	17fd                	addi	a5,a5,-1
    800014ae:	00f60733          	add	a4,a2,a5
    800014b2:	767d                	lui	a2,0xfffff
    800014b4:	8f71                	and	a4,a4,a2
    800014b6:	97ae                	add	a5,a5,a1
    800014b8:	8ff1                	and	a5,a5,a2
    800014ba:	00f76863          	bltu	a4,a5,800014ca <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014be:	8526                	mv	a0,s1
    800014c0:	60e2                	ld	ra,24(sp)
    800014c2:	6442                	ld	s0,16(sp)
    800014c4:	64a2                	ld	s1,8(sp)
    800014c6:	6105                	addi	sp,sp,32
    800014c8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ca:	8f99                	sub	a5,a5,a4
    800014cc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ce:	4685                	li	a3,1
    800014d0:	0007861b          	sext.w	a2,a5
    800014d4:	85ba                	mv	a1,a4
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	e5e080e7          	jalr	-418(ra) # 80001334 <uvmunmap>
    800014de:	b7c5                	j	800014be <uvmdealloc+0x26>

00000000800014e0 <uvmalloc>:
  if(newsz < oldsz)
    800014e0:	0ab66163          	bltu	a2,a1,80001582 <uvmalloc+0xa2>
{
    800014e4:	7139                	addi	sp,sp,-64
    800014e6:	fc06                	sd	ra,56(sp)
    800014e8:	f822                	sd	s0,48(sp)
    800014ea:	f426                	sd	s1,40(sp)
    800014ec:	f04a                	sd	s2,32(sp)
    800014ee:	ec4e                	sd	s3,24(sp)
    800014f0:	e852                	sd	s4,16(sp)
    800014f2:	e456                	sd	s5,8(sp)
    800014f4:	0080                	addi	s0,sp,64
    800014f6:	8aaa                	mv	s5,a0
    800014f8:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014fa:	6985                	lui	s3,0x1
    800014fc:	19fd                	addi	s3,s3,-1
    800014fe:	95ce                	add	a1,a1,s3
    80001500:	79fd                	lui	s3,0xfffff
    80001502:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001506:	08c9f063          	bgeu	s3,a2,80001586 <uvmalloc+0xa6>
    8000150a:	894e                	mv	s2,s3
    mem = kalloc();
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	676080e7          	jalr	1654(ra) # 80000b82 <kalloc>
    80001514:	84aa                	mv	s1,a0
    if(mem == 0){
    80001516:	c51d                	beqz	a0,80001544 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001518:	6605                	lui	a2,0x1
    8000151a:	4581                	li	a1,0
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	852080e7          	jalr	-1966(ra) # 80000d6e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001524:	4779                	li	a4,30
    80001526:	86a6                	mv	a3,s1
    80001528:	6605                	lui	a2,0x1
    8000152a:	85ca                	mv	a1,s2
    8000152c:	8556                	mv	a0,s5
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	c6e080e7          	jalr	-914(ra) # 8000119c <mappages>
    80001536:	e905                	bnez	a0,80001566 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001538:	6785                	lui	a5,0x1
    8000153a:	993e                	add	s2,s2,a5
    8000153c:	fd4968e3          	bltu	s2,s4,8000150c <uvmalloc+0x2c>
  return newsz;
    80001540:	8552                	mv	a0,s4
    80001542:	a809                	j	80001554 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001544:	864e                	mv	a2,s3
    80001546:	85ca                	mv	a1,s2
    80001548:	8556                	mv	a0,s5
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	f4e080e7          	jalr	-178(ra) # 80001498 <uvmdealloc>
      return 0;
    80001552:	4501                	li	a0,0
}
    80001554:	70e2                	ld	ra,56(sp)
    80001556:	7442                	ld	s0,48(sp)
    80001558:	74a2                	ld	s1,40(sp)
    8000155a:	7902                	ld	s2,32(sp)
    8000155c:	69e2                	ld	s3,24(sp)
    8000155e:	6a42                	ld	s4,16(sp)
    80001560:	6aa2                	ld	s5,8(sp)
    80001562:	6121                	addi	sp,sp,64
    80001564:	8082                	ret
      kfree(mem);
    80001566:	8526                	mv	a0,s1
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	51e080e7          	jalr	1310(ra) # 80000a86 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001570:	864e                	mv	a2,s3
    80001572:	85ca                	mv	a1,s2
    80001574:	8556                	mv	a0,s5
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	f22080e7          	jalr	-222(ra) # 80001498 <uvmdealloc>
      return 0;
    8000157e:	4501                	li	a0,0
    80001580:	bfd1                	j	80001554 <uvmalloc+0x74>
    return oldsz;
    80001582:	852e                	mv	a0,a1
}
    80001584:	8082                	ret
  return newsz;
    80001586:	8532                	mv	a0,a2
    80001588:	b7f1                	j	80001554 <uvmalloc+0x74>

000000008000158a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000158a:	7179                	addi	sp,sp,-48
    8000158c:	f406                	sd	ra,40(sp)
    8000158e:	f022                	sd	s0,32(sp)
    80001590:	ec26                	sd	s1,24(sp)
    80001592:	e84a                	sd	s2,16(sp)
    80001594:	e44e                	sd	s3,8(sp)
    80001596:	e052                	sd	s4,0(sp)
    80001598:	1800                	addi	s0,sp,48
    8000159a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000159c:	84aa                	mv	s1,a0
    8000159e:	6905                	lui	s2,0x1
    800015a0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a2:	4985                	li	s3,1
    800015a4:	a821                	j	800015bc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015a8:	0532                	slli	a0,a0,0xc
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	fe0080e7          	jalr	-32(ra) # 8000158a <freewalk>
      pagetable[i] = 0;
    800015b2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b6:	04a1                	addi	s1,s1,8
    800015b8:	03248163          	beq	s1,s2,800015da <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015bc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015be:	00f57793          	andi	a5,a0,15
    800015c2:	ff3782e3          	beq	a5,s3,800015a6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c6:	8905                	andi	a0,a0,1
    800015c8:	d57d                	beqz	a0,800015b6 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015ca:	00007517          	auipc	a0,0x7
    800015ce:	bb650513          	addi	a0,a0,-1098 # 80008180 <digits+0x128>
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	00e080e7          	jalr	14(ra) # 800005e0 <panic>
    }
  }
  kfree((void*)pagetable);
    800015da:	8552                	mv	a0,s4
    800015dc:	fffff097          	auipc	ra,0xfffff
    800015e0:	4aa080e7          	jalr	1194(ra) # 80000a86 <kfree>
}
    800015e4:	70a2                	ld	ra,40(sp)
    800015e6:	7402                	ld	s0,32(sp)
    800015e8:	64e2                	ld	s1,24(sp)
    800015ea:	6942                	ld	s2,16(sp)
    800015ec:	69a2                	ld	s3,8(sp)
    800015ee:	6a02                	ld	s4,0(sp)
    800015f0:	6145                	addi	sp,sp,48
    800015f2:	8082                	ret

00000000800015f4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f4:	1101                	addi	sp,sp,-32
    800015f6:	ec06                	sd	ra,24(sp)
    800015f8:	e822                	sd	s0,16(sp)
    800015fa:	e426                	sd	s1,8(sp)
    800015fc:	1000                	addi	s0,sp,32
    800015fe:	84aa                	mv	s1,a0
  if(sz > 0)
    80001600:	e999                	bnez	a1,80001616 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001602:	8526                	mv	a0,s1
    80001604:	00000097          	auipc	ra,0x0
    80001608:	f86080e7          	jalr	-122(ra) # 8000158a <freewalk>
}
    8000160c:	60e2                	ld	ra,24(sp)
    8000160e:	6442                	ld	s0,16(sp)
    80001610:	64a2                	ld	s1,8(sp)
    80001612:	6105                	addi	sp,sp,32
    80001614:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001616:	6605                	lui	a2,0x1
    80001618:	167d                	addi	a2,a2,-1
    8000161a:	962e                	add	a2,a2,a1
    8000161c:	4685                	li	a3,1
    8000161e:	8231                	srli	a2,a2,0xc
    80001620:	4581                	li	a1,0
    80001622:	00000097          	auipc	ra,0x0
    80001626:	d12080e7          	jalr	-750(ra) # 80001334 <uvmunmap>
    8000162a:	bfe1                	j	80001602 <uvmfree+0xe>

000000008000162c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000162c:	c679                	beqz	a2,800016fa <uvmcopy+0xce>
{
    8000162e:	715d                	addi	sp,sp,-80
    80001630:	e486                	sd	ra,72(sp)
    80001632:	e0a2                	sd	s0,64(sp)
    80001634:	fc26                	sd	s1,56(sp)
    80001636:	f84a                	sd	s2,48(sp)
    80001638:	f44e                	sd	s3,40(sp)
    8000163a:	f052                	sd	s4,32(sp)
    8000163c:	ec56                	sd	s5,24(sp)
    8000163e:	e85a                	sd	s6,16(sp)
    80001640:	e45e                	sd	s7,8(sp)
    80001642:	0880                	addi	s0,sp,80
    80001644:	8b2a                	mv	s6,a0
    80001646:	8aae                	mv	s5,a1
    80001648:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000164a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000164c:	4601                	li	a2,0
    8000164e:	85ce                	mv	a1,s3
    80001650:	855a                	mv	a0,s6
    80001652:	00000097          	auipc	ra,0x0
    80001656:	a04080e7          	jalr	-1532(ra) # 80001056 <walk>
    8000165a:	c531                	beqz	a0,800016a6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000165c:	6118                	ld	a4,0(a0)
    8000165e:	00177793          	andi	a5,a4,1
    80001662:	cbb1                	beqz	a5,800016b6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001664:	00a75593          	srli	a1,a4,0xa
    80001668:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000166c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	512080e7          	jalr	1298(ra) # 80000b82 <kalloc>
    80001678:	892a                	mv	s2,a0
    8000167a:	c939                	beqz	a0,800016d0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000167c:	6605                	lui	a2,0x1
    8000167e:	85de                	mv	a1,s7
    80001680:	fffff097          	auipc	ra,0xfffff
    80001684:	74a080e7          	jalr	1866(ra) # 80000dca <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001688:	8726                	mv	a4,s1
    8000168a:	86ca                	mv	a3,s2
    8000168c:	6605                	lui	a2,0x1
    8000168e:	85ce                	mv	a1,s3
    80001690:	8556                	mv	a0,s5
    80001692:	00000097          	auipc	ra,0x0
    80001696:	b0a080e7          	jalr	-1270(ra) # 8000119c <mappages>
    8000169a:	e515                	bnez	a0,800016c6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000169c:	6785                	lui	a5,0x1
    8000169e:	99be                	add	s3,s3,a5
    800016a0:	fb49e6e3          	bltu	s3,s4,8000164c <uvmcopy+0x20>
    800016a4:	a081                	j	800016e4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016a6:	00007517          	auipc	a0,0x7
    800016aa:	aea50513          	addi	a0,a0,-1302 # 80008190 <digits+0x138>
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	f32080e7          	jalr	-206(ra) # 800005e0 <panic>
      panic("uvmcopy: page not present");
    800016b6:	00007517          	auipc	a0,0x7
    800016ba:	afa50513          	addi	a0,a0,-1286 # 800081b0 <digits+0x158>
    800016be:	fffff097          	auipc	ra,0xfffff
    800016c2:	f22080e7          	jalr	-222(ra) # 800005e0 <panic>
      kfree(mem);
    800016c6:	854a                	mv	a0,s2
    800016c8:	fffff097          	auipc	ra,0xfffff
    800016cc:	3be080e7          	jalr	958(ra) # 80000a86 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016d0:	4685                	li	a3,1
    800016d2:	00c9d613          	srli	a2,s3,0xc
    800016d6:	4581                	li	a1,0
    800016d8:	8556                	mv	a0,s5
    800016da:	00000097          	auipc	ra,0x0
    800016de:	c5a080e7          	jalr	-934(ra) # 80001334 <uvmunmap>
  return -1;
    800016e2:	557d                	li	a0,-1
}
    800016e4:	60a6                	ld	ra,72(sp)
    800016e6:	6406                	ld	s0,64(sp)
    800016e8:	74e2                	ld	s1,56(sp)
    800016ea:	7942                	ld	s2,48(sp)
    800016ec:	79a2                	ld	s3,40(sp)
    800016ee:	7a02                	ld	s4,32(sp)
    800016f0:	6ae2                	ld	s5,24(sp)
    800016f2:	6b42                	ld	s6,16(sp)
    800016f4:	6ba2                	ld	s7,8(sp)
    800016f6:	6161                	addi	sp,sp,80
    800016f8:	8082                	ret
  return 0;
    800016fa:	4501                	li	a0,0
}
    800016fc:	8082                	ret

00000000800016fe <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016fe:	1141                	addi	sp,sp,-16
    80001700:	e406                	sd	ra,8(sp)
    80001702:	e022                	sd	s0,0(sp)
    80001704:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001706:	4601                	li	a2,0
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	94e080e7          	jalr	-1714(ra) # 80001056 <walk>
  if(pte == 0)
    80001710:	c901                	beqz	a0,80001720 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001712:	611c                	ld	a5,0(a0)
    80001714:	9bbd                	andi	a5,a5,-17
    80001716:	e11c                	sd	a5,0(a0)
}
    80001718:	60a2                	ld	ra,8(sp)
    8000171a:	6402                	ld	s0,0(sp)
    8000171c:	0141                	addi	sp,sp,16
    8000171e:	8082                	ret
    panic("uvmclear");
    80001720:	00007517          	auipc	a0,0x7
    80001724:	ab050513          	addi	a0,a0,-1360 # 800081d0 <digits+0x178>
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	eb8080e7          	jalr	-328(ra) # 800005e0 <panic>

0000000080001730 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001730:	c6bd                	beqz	a3,8000179e <copyout+0x6e>
{
    80001732:	715d                	addi	sp,sp,-80
    80001734:	e486                	sd	ra,72(sp)
    80001736:	e0a2                	sd	s0,64(sp)
    80001738:	fc26                	sd	s1,56(sp)
    8000173a:	f84a                	sd	s2,48(sp)
    8000173c:	f44e                	sd	s3,40(sp)
    8000173e:	f052                	sd	s4,32(sp)
    80001740:	ec56                	sd	s5,24(sp)
    80001742:	e85a                	sd	s6,16(sp)
    80001744:	e45e                	sd	s7,8(sp)
    80001746:	e062                	sd	s8,0(sp)
    80001748:	0880                	addi	s0,sp,80
    8000174a:	8b2a                	mv	s6,a0
    8000174c:	8c2e                	mv	s8,a1
    8000174e:	8a32                	mv	s4,a2
    80001750:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001752:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001754:	6a85                	lui	s5,0x1
    80001756:	a015                	j	8000177a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001758:	9562                	add	a0,a0,s8
    8000175a:	0004861b          	sext.w	a2,s1
    8000175e:	85d2                	mv	a1,s4
    80001760:	41250533          	sub	a0,a0,s2
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	666080e7          	jalr	1638(ra) # 80000dca <memmove>

    len -= n;
    8000176c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001770:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001772:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001776:	02098263          	beqz	s3,8000179a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000177a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177e:	85ca                	mv	a1,s2
    80001780:	855a                	mv	a0,s6
    80001782:	00000097          	auipc	ra,0x0
    80001786:	97a080e7          	jalr	-1670(ra) # 800010fc <walkaddr>
    if(pa0 == 0)
    8000178a:	cd01                	beqz	a0,800017a2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000178c:	418904b3          	sub	s1,s2,s8
    80001790:	94d6                	add	s1,s1,s5
    if(n > len)
    80001792:	fc99f3e3          	bgeu	s3,s1,80001758 <copyout+0x28>
    80001796:	84ce                	mv	s1,s3
    80001798:	b7c1                	j	80001758 <copyout+0x28>
  }
  return 0;
    8000179a:	4501                	li	a0,0
    8000179c:	a021                	j	800017a4 <copyout+0x74>
    8000179e:	4501                	li	a0,0
}
    800017a0:	8082                	ret
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
    800017b6:	6c02                	ld	s8,0(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret

00000000800017bc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017bc:	caa5                	beqz	a3,8000182c <copyin+0x70>
{
    800017be:	715d                	addi	sp,sp,-80
    800017c0:	e486                	sd	ra,72(sp)
    800017c2:	e0a2                	sd	s0,64(sp)
    800017c4:	fc26                	sd	s1,56(sp)
    800017c6:	f84a                	sd	s2,48(sp)
    800017c8:	f44e                	sd	s3,40(sp)
    800017ca:	f052                	sd	s4,32(sp)
    800017cc:	ec56                	sd	s5,24(sp)
    800017ce:	e85a                	sd	s6,16(sp)
    800017d0:	e45e                	sd	s7,8(sp)
    800017d2:	e062                	sd	s8,0(sp)
    800017d4:	0880                	addi	s0,sp,80
    800017d6:	8b2a                	mv	s6,a0
    800017d8:	8a2e                	mv	s4,a1
    800017da:	8c32                	mv	s8,a2
    800017dc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017de:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e0:	6a85                	lui	s5,0x1
    800017e2:	a01d                	j	80001808 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e4:	018505b3          	add	a1,a0,s8
    800017e8:	0004861b          	sext.w	a2,s1
    800017ec:	412585b3          	sub	a1,a1,s2
    800017f0:	8552                	mv	a0,s4
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	5d8080e7          	jalr	1496(ra) # 80000dca <memmove>

    len -= n;
    800017fa:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017fe:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001800:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001804:	02098263          	beqz	s3,80001828 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001808:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000180c:	85ca                	mv	a1,s2
    8000180e:	855a                	mv	a0,s6
    80001810:	00000097          	auipc	ra,0x0
    80001814:	8ec080e7          	jalr	-1812(ra) # 800010fc <walkaddr>
    if(pa0 == 0)
    80001818:	cd01                	beqz	a0,80001830 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000181a:	418904b3          	sub	s1,s2,s8
    8000181e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001820:	fc99f2e3          	bgeu	s3,s1,800017e4 <copyin+0x28>
    80001824:	84ce                	mv	s1,s3
    80001826:	bf7d                	j	800017e4 <copyin+0x28>
  }
  return 0;
    80001828:	4501                	li	a0,0
    8000182a:	a021                	j	80001832 <copyin+0x76>
    8000182c:	4501                	li	a0,0
}
    8000182e:	8082                	ret
      return -1;
    80001830:	557d                	li	a0,-1
}
    80001832:	60a6                	ld	ra,72(sp)
    80001834:	6406                	ld	s0,64(sp)
    80001836:	74e2                	ld	s1,56(sp)
    80001838:	7942                	ld	s2,48(sp)
    8000183a:	79a2                	ld	s3,40(sp)
    8000183c:	7a02                	ld	s4,32(sp)
    8000183e:	6ae2                	ld	s5,24(sp)
    80001840:	6b42                	ld	s6,16(sp)
    80001842:	6ba2                	ld	s7,8(sp)
    80001844:	6c02                	ld	s8,0(sp)
    80001846:	6161                	addi	sp,sp,80
    80001848:	8082                	ret

000000008000184a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000184a:	c6c5                	beqz	a3,800018f2 <copyinstr+0xa8>
{
    8000184c:	715d                	addi	sp,sp,-80
    8000184e:	e486                	sd	ra,72(sp)
    80001850:	e0a2                	sd	s0,64(sp)
    80001852:	fc26                	sd	s1,56(sp)
    80001854:	f84a                	sd	s2,48(sp)
    80001856:	f44e                	sd	s3,40(sp)
    80001858:	f052                	sd	s4,32(sp)
    8000185a:	ec56                	sd	s5,24(sp)
    8000185c:	e85a                	sd	s6,16(sp)
    8000185e:	e45e                	sd	s7,8(sp)
    80001860:	0880                	addi	s0,sp,80
    80001862:	8a2a                	mv	s4,a0
    80001864:	8b2e                	mv	s6,a1
    80001866:	8bb2                	mv	s7,a2
    80001868:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000186a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186c:	6985                	lui	s3,0x1
    8000186e:	a035                	j	8000189a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001870:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001874:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001876:	0017b793          	seqz	a5,a5
    8000187a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000187e:	60a6                	ld	ra,72(sp)
    80001880:	6406                	ld	s0,64(sp)
    80001882:	74e2                	ld	s1,56(sp)
    80001884:	7942                	ld	s2,48(sp)
    80001886:	79a2                	ld	s3,40(sp)
    80001888:	7a02                	ld	s4,32(sp)
    8000188a:	6ae2                	ld	s5,24(sp)
    8000188c:	6b42                	ld	s6,16(sp)
    8000188e:	6ba2                	ld	s7,8(sp)
    80001890:	6161                	addi	sp,sp,80
    80001892:	8082                	ret
    srcva = va0 + PGSIZE;
    80001894:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001898:	c8a9                	beqz	s1,800018ea <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000189a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000189e:	85ca                	mv	a1,s2
    800018a0:	8552                	mv	a0,s4
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	85a080e7          	jalr	-1958(ra) # 800010fc <walkaddr>
    if(pa0 == 0)
    800018aa:	c131                	beqz	a0,800018ee <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018ac:	41790833          	sub	a6,s2,s7
    800018b0:	984e                	add	a6,a6,s3
    if(n > max)
    800018b2:	0104f363          	bgeu	s1,a6,800018b8 <copyinstr+0x6e>
    800018b6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b8:	955e                	add	a0,a0,s7
    800018ba:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018be:	fc080be3          	beqz	a6,80001894 <copyinstr+0x4a>
    800018c2:	985a                	add	a6,a6,s6
    800018c4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018c6:	41650633          	sub	a2,a0,s6
    800018ca:	14fd                	addi	s1,s1,-1
    800018cc:	9b26                	add	s6,s6,s1
    800018ce:	00f60733          	add	a4,a2,a5
    800018d2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018d6:	df49                	beqz	a4,80001870 <copyinstr+0x26>
        *dst = *p;
    800018d8:	00e78023          	sb	a4,0(a5)
      --max;
    800018dc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018e0:	0785                	addi	a5,a5,1
    while(n > 0){
    800018e2:	ff0796e3          	bne	a5,a6,800018ce <copyinstr+0x84>
      dst++;
    800018e6:	8b42                	mv	s6,a6
    800018e8:	b775                	j	80001894 <copyinstr+0x4a>
    800018ea:	4781                	li	a5,0
    800018ec:	b769                	j	80001876 <copyinstr+0x2c>
      return -1;
    800018ee:	557d                	li	a0,-1
    800018f0:	b779                	j	8000187e <copyinstr+0x34>
  int got_null = 0;
    800018f2:	4781                	li	a5,0
  if(got_null){
    800018f4:	0017b793          	seqz	a5,a5
    800018f8:	40f00533          	neg	a0,a5
}
    800018fc:	8082                	ret

00000000800018fe <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018fe:	1101                	addi	sp,sp,-32
    80001900:	ec06                	sd	ra,24(sp)
    80001902:	e822                	sd	s0,16(sp)
    80001904:	e426                	sd	s1,8(sp)
    80001906:	1000                	addi	s0,sp,32
    80001908:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	2ee080e7          	jalr	750(ra) # 80000bf8 <holding>
    80001912:	c909                	beqz	a0,80001924 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001914:	749c                	ld	a5,40(s1)
    80001916:	00978f63          	beq	a5,s1,80001934 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000191a:	60e2                	ld	ra,24(sp)
    8000191c:	6442                	ld	s0,16(sp)
    8000191e:	64a2                	ld	s1,8(sp)
    80001920:	6105                	addi	sp,sp,32
    80001922:	8082                	ret
    panic("wakeup1");
    80001924:	00007517          	auipc	a0,0x7
    80001928:	8bc50513          	addi	a0,a0,-1860 # 800081e0 <digits+0x188>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	cb4080e7          	jalr	-844(ra) # 800005e0 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001934:	4c98                	lw	a4,24(s1)
    80001936:	4785                	li	a5,1
    80001938:	fef711e3          	bne	a4,a5,8000191a <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000193c:	4789                	li	a5,2
    8000193e:	cc9c                	sw	a5,24(s1)
}
    80001940:	bfe9                	j	8000191a <wakeup1+0x1c>

0000000080001942 <procinit>:
{
    80001942:	715d                	addi	sp,sp,-80
    80001944:	e486                	sd	ra,72(sp)
    80001946:	e0a2                	sd	s0,64(sp)
    80001948:	fc26                	sd	s1,56(sp)
    8000194a:	f84a                	sd	s2,48(sp)
    8000194c:	f44e                	sd	s3,40(sp)
    8000194e:	f052                	sd	s4,32(sp)
    80001950:	ec56                	sd	s5,24(sp)
    80001952:	e85a                	sd	s6,16(sp)
    80001954:	e45e                	sd	s7,8(sp)
    80001956:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001958:	00007597          	auipc	a1,0x7
    8000195c:	89058593          	addi	a1,a1,-1904 # 800081e8 <digits+0x190>
    80001960:	00010517          	auipc	a0,0x10
    80001964:	ff050513          	addi	a0,a0,-16 # 80011950 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	27a080e7          	jalr	634(ra) # 80000be2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	00010917          	auipc	s2,0x10
    80001974:	3f890913          	addi	s2,s2,1016 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001978:	00007b97          	auipc	s7,0x7
    8000197c:	878b8b93          	addi	s7,s7,-1928 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001980:	8b4a                	mv	s6,s2
    80001982:	00006a97          	auipc	s5,0x6
    80001986:	67ea8a93          	addi	s5,s5,1662 # 80008000 <etext>
    8000198a:	040009b7          	lui	s3,0x4000
    8000198e:	19fd                	addi	s3,s3,-1
    80001990:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001992:	00016a17          	auipc	s4,0x16
    80001996:	5d6a0a13          	addi	s4,s4,1494 # 80017f68 <tickslock>
      initlock(&p->lock, "proc");
    8000199a:	85de                	mv	a1,s7
    8000199c:	854a                	mv	a0,s2
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	244080e7          	jalr	580(ra) # 80000be2 <initlock>
      char *pa = kalloc();
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	1dc080e7          	jalr	476(ra) # 80000b82 <kalloc>
    800019ae:	85aa                	mv	a1,a0
      if(pa == 0)
    800019b0:	c929                	beqz	a0,80001a02 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019b2:	416904b3          	sub	s1,s2,s6
    800019b6:	848d                	srai	s1,s1,0x3
    800019b8:	000ab783          	ld	a5,0(s5)
    800019bc:	02f484b3          	mul	s1,s1,a5
    800019c0:	2485                	addiw	s1,s1,1
    800019c2:	00d4949b          	slliw	s1,s1,0xd
    800019c6:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ca:	4699                	li	a3,6
    800019cc:	6605                	lui	a2,0x1
    800019ce:	8526                	mv	a0,s1
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	85a080e7          	jalr	-1958(ra) # 8000122a <kvmmap>
      p->kstack = va;
    800019d8:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	18890913          	addi	s2,s2,392
    800019e0:	fb491de3          	bne	s2,s4,8000199a <procinit+0x58>
  kvminithart();
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	64e080e7          	jalr	1614(ra) # 80001032 <kvminithart>
}
    800019ec:	60a6                	ld	ra,72(sp)
    800019ee:	6406                	ld	s0,64(sp)
    800019f0:	74e2                	ld	s1,56(sp)
    800019f2:	7942                	ld	s2,48(sp)
    800019f4:	79a2                	ld	s3,40(sp)
    800019f6:	7a02                	ld	s4,32(sp)
    800019f8:	6ae2                	ld	s5,24(sp)
    800019fa:	6b42                	ld	s6,16(sp)
    800019fc:	6ba2                	ld	s7,8(sp)
    800019fe:	6161                	addi	sp,sp,80
    80001a00:	8082                	ret
        panic("kalloc");
    80001a02:	00006517          	auipc	a0,0x6
    80001a06:	7f650513          	addi	a0,a0,2038 # 800081f8 <digits+0x1a0>
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	bd6080e7          	jalr	-1066(ra) # 800005e0 <panic>

0000000080001a12 <cpuid>:
{
    80001a12:	1141                	addi	sp,sp,-16
    80001a14:	e422                	sd	s0,8(sp)
    80001a16:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a18:	8512                	mv	a0,tp
}
    80001a1a:	2501                	sext.w	a0,a0
    80001a1c:	6422                	ld	s0,8(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret

0000000080001a22 <mycpu>:
mycpu(void) {
    80001a22:	1141                	addi	sp,sp,-16
    80001a24:	e422                	sd	s0,8(sp)
    80001a26:	0800                	addi	s0,sp,16
    80001a28:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a2a:	2781                	sext.w	a5,a5
    80001a2c:	079e                	slli	a5,a5,0x7
}
    80001a2e:	00010517          	auipc	a0,0x10
    80001a32:	f3a50513          	addi	a0,a0,-198 # 80011968 <cpus>
    80001a36:	953e                	add	a0,a0,a5
    80001a38:	6422                	ld	s0,8(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret

0000000080001a3e <myproc>:
myproc(void) {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	1000                	addi	s0,sp,32
  push_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	1de080e7          	jalr	478(ra) # 80000c26 <push_off>
    80001a50:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a52:	2781                	sext.w	a5,a5
    80001a54:	079e                	slli	a5,a5,0x7
    80001a56:	00010717          	auipc	a4,0x10
    80001a5a:	efa70713          	addi	a4,a4,-262 # 80011950 <pid_lock>
    80001a5e:	97ba                	add	a5,a5,a4
    80001a60:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	264080e7          	jalr	612(ra) # 80000cc6 <pop_off>
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6105                	addi	sp,sp,32
    80001a74:	8082                	ret

0000000080001a76 <forkret>:
{
    80001a76:	1141                	addi	sp,sp,-16
    80001a78:	e406                	sd	ra,8(sp)
    80001a7a:	e022                	sd	s0,0(sp)
    80001a7c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	fc0080e7          	jalr	-64(ra) # 80001a3e <myproc>
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	2a0080e7          	jalr	672(ra) # 80000d26 <release>
  if (first) {
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	db27a783          	lw	a5,-590(a5) # 80008840 <first.1>
    80001a96:	eb89                	bnez	a5,80001aa8 <forkret+0x32>
  usertrapret();
    80001a98:	00001097          	auipc	ra,0x1
    80001a9c:	c50080e7          	jalr	-944(ra) # 800026e8 <usertrapret>
}
    80001aa0:	60a2                	ld	ra,8(sp)
    80001aa2:	6402                	ld	s0,0(sp)
    80001aa4:	0141                	addi	sp,sp,16
    80001aa6:	8082                	ret
    first = 0;
    80001aa8:	00007797          	auipc	a5,0x7
    80001aac:	d807ac23          	sw	zero,-616(a5) # 80008840 <first.1>
    fsinit(ROOTDEV);
    80001ab0:	4505                	li	a0,1
    80001ab2:	00002097          	auipc	ra,0x2
    80001ab6:	ab8080e7          	jalr	-1352(ra) # 8000356a <fsinit>
    80001aba:	bff9                	j	80001a98 <forkret+0x22>

0000000080001abc <allocpid>:
allocpid() {
    80001abc:	1101                	addi	sp,sp,-32
    80001abe:	ec06                	sd	ra,24(sp)
    80001ac0:	e822                	sd	s0,16(sp)
    80001ac2:	e426                	sd	s1,8(sp)
    80001ac4:	e04a                	sd	s2,0(sp)
    80001ac6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac8:	00010917          	auipc	s2,0x10
    80001acc:	e8890913          	addi	s2,s2,-376 # 80011950 <pid_lock>
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	1a0080e7          	jalr	416(ra) # 80000c72 <acquire>
  pid = nextpid;
    80001ada:	00007797          	auipc	a5,0x7
    80001ade:	d6a78793          	addi	a5,a5,-662 # 80008844 <nextpid>
    80001ae2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae4:	0014871b          	addiw	a4,s1,1
    80001ae8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aea:	854a                	mv	a0,s2
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	23a080e7          	jalr	570(ra) # 80000d26 <release>
}
    80001af4:	8526                	mv	a0,s1
    80001af6:	60e2                	ld	ra,24(sp)
    80001af8:	6442                	ld	s0,16(sp)
    80001afa:	64a2                	ld	s1,8(sp)
    80001afc:	6902                	ld	s2,0(sp)
    80001afe:	6105                	addi	sp,sp,32
    80001b00:	8082                	ret

0000000080001b02 <proc_pagetable>:
{
    80001b02:	1101                	addi	sp,sp,-32
    80001b04:	ec06                	sd	ra,24(sp)
    80001b06:	e822                	sd	s0,16(sp)
    80001b08:	e426                	sd	s1,8(sp)
    80001b0a:	e04a                	sd	s2,0(sp)
    80001b0c:	1000                	addi	s0,sp,32
    80001b0e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b10:	00000097          	auipc	ra,0x0
    80001b14:	8e8080e7          	jalr	-1816(ra) # 800013f8 <uvmcreate>
    80001b18:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1a:	c121                	beqz	a0,80001b5a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b1c:	4729                	li	a4,10
    80001b1e:	00005697          	auipc	a3,0x5
    80001b22:	4e268693          	addi	a3,a3,1250 # 80007000 <_trampoline>
    80001b26:	6605                	lui	a2,0x1
    80001b28:	040005b7          	lui	a1,0x4000
    80001b2c:	15fd                	addi	a1,a1,-1
    80001b2e:	05b2                	slli	a1,a1,0xc
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	66c080e7          	jalr	1644(ra) # 8000119c <mappages>
    80001b38:	02054863          	bltz	a0,80001b68 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b3c:	4719                	li	a4,6
    80001b3e:	05893683          	ld	a3,88(s2)
    80001b42:	6605                	lui	a2,0x1
    80001b44:	020005b7          	lui	a1,0x2000
    80001b48:	15fd                	addi	a1,a1,-1
    80001b4a:	05b6                	slli	a1,a1,0xd
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	64e080e7          	jalr	1614(ra) # 8000119c <mappages>
    80001b56:	02054163          	bltz	a0,80001b78 <proc_pagetable+0x76>
}
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	60e2                	ld	ra,24(sp)
    80001b5e:	6442                	ld	s0,16(sp)
    80001b60:	64a2                	ld	s1,8(sp)
    80001b62:	6902                	ld	s2,0(sp)
    80001b64:	6105                	addi	sp,sp,32
    80001b66:	8082                	ret
    uvmfree(pagetable, 0);
    80001b68:	4581                	li	a1,0
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	a88080e7          	jalr	-1400(ra) # 800015f4 <uvmfree>
    return 0;
    80001b74:	4481                	li	s1,0
    80001b76:	b7d5                	j	80001b5a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b78:	4681                	li	a3,0
    80001b7a:	4605                	li	a2,1
    80001b7c:	040005b7          	lui	a1,0x4000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b2                	slli	a1,a1,0xc
    80001b84:	8526                	mv	a0,s1
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	7ae080e7          	jalr	1966(ra) # 80001334 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b8e:	4581                	li	a1,0
    80001b90:	8526                	mv	a0,s1
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	a62080e7          	jalr	-1438(ra) # 800015f4 <uvmfree>
    return 0;
    80001b9a:	4481                	li	s1,0
    80001b9c:	bf7d                	j	80001b5a <proc_pagetable+0x58>

0000000080001b9e <proc_freepagetable>:
{
    80001b9e:	1101                	addi	sp,sp,-32
    80001ba0:	ec06                	sd	ra,24(sp)
    80001ba2:	e822                	sd	s0,16(sp)
    80001ba4:	e426                	sd	s1,8(sp)
    80001ba6:	e04a                	sd	s2,0(sp)
    80001ba8:	1000                	addi	s0,sp,32
    80001baa:	84aa                	mv	s1,a0
    80001bac:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bae:	4681                	li	a3,0
    80001bb0:	4605                	li	a2,1
    80001bb2:	040005b7          	lui	a1,0x4000
    80001bb6:	15fd                	addi	a1,a1,-1
    80001bb8:	05b2                	slli	a1,a1,0xc
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	77a080e7          	jalr	1914(ra) # 80001334 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc2:	4681                	li	a3,0
    80001bc4:	4605                	li	a2,1
    80001bc6:	020005b7          	lui	a1,0x2000
    80001bca:	15fd                	addi	a1,a1,-1
    80001bcc:	05b6                	slli	a1,a1,0xd
    80001bce:	8526                	mv	a0,s1
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	764080e7          	jalr	1892(ra) # 80001334 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd8:	85ca                	mv	a1,s2
    80001bda:	8526                	mv	a0,s1
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	a18080e7          	jalr	-1512(ra) # 800015f4 <uvmfree>
}
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6902                	ld	s2,0(sp)
    80001bec:	6105                	addi	sp,sp,32
    80001bee:	8082                	ret

0000000080001bf0 <freeproc>:
{
    80001bf0:	1101                	addi	sp,sp,-32
    80001bf2:	ec06                	sd	ra,24(sp)
    80001bf4:	e822                	sd	s0,16(sp)
    80001bf6:	e426                	sd	s1,8(sp)
    80001bf8:	1000                	addi	s0,sp,32
    80001bfa:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bfc:	6d28                	ld	a0,88(a0)
    80001bfe:	c509                	beqz	a0,80001c08 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	e86080e7          	jalr	-378(ra) # 80000a86 <kfree>
  p->trapframe = 0;
    80001c08:	0404bc23          	sd	zero,88(s1)
  if(p->alarm_trapframe)
    80001c0c:	70a8                	ld	a0,96(s1)
    80001c0e:	c509                	beqz	a0,80001c18 <freeproc+0x28>
    kfree((void*)p->alarm_trapframe);
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	e76080e7          	jalr	-394(ra) # 80000a86 <kfree>
  p->alarm_trapframe=0;
    80001c18:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001c1c:	68a8                	ld	a0,80(s1)
    80001c1e:	c511                	beqz	a0,80001c2a <freeproc+0x3a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c20:	64ac                	ld	a1,72(s1)
    80001c22:	00000097          	auipc	ra,0x0
    80001c26:	f7c080e7          	jalr	-132(ra) # 80001b9e <proc_freepagetable>
  p->pagetable = 0;
    80001c2a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c2e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c32:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c36:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c3a:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001c3e:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c42:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c46:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c4a:	0004ac23          	sw	zero,24(s1)
}
    80001c4e:	60e2                	ld	ra,24(sp)
    80001c50:	6442                	ld	s0,16(sp)
    80001c52:	64a2                	ld	s1,8(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret

0000000080001c58 <allocproc>:
{
    80001c58:	1101                	addi	sp,sp,-32
    80001c5a:	ec06                	sd	ra,24(sp)
    80001c5c:	e822                	sd	s0,16(sp)
    80001c5e:	e426                	sd	s1,8(sp)
    80001c60:	e04a                	sd	s2,0(sp)
    80001c62:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c64:	00010497          	auipc	s1,0x10
    80001c68:	10448493          	addi	s1,s1,260 # 80011d68 <proc>
    80001c6c:	00016917          	auipc	s2,0x16
    80001c70:	2fc90913          	addi	s2,s2,764 # 80017f68 <tickslock>
    acquire(&p->lock);
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	ffc080e7          	jalr	-4(ra) # 80000c72 <acquire>
    if(p->state == UNUSED) {
    80001c7e:	4c9c                	lw	a5,24(s1)
    80001c80:	cf81                	beqz	a5,80001c98 <allocproc+0x40>
      release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	0a2080e7          	jalr	162(ra) # 80000d26 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c8c:	18848493          	addi	s1,s1,392
    80001c90:	ff2492e3          	bne	s1,s2,80001c74 <allocproc+0x1c>
  return 0;
    80001c94:	4481                	li	s1,0
    80001c96:	a0b5                	j	80001d02 <allocproc+0xaa>
  p->pid = allocpid();
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	e24080e7          	jalr	-476(ra) # 80001abc <allocpid>
    80001ca0:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	ee0080e7          	jalr	-288(ra) # 80000b82 <kalloc>
    80001caa:	892a                	mv	s2,a0
    80001cac:	eca8                	sd	a0,88(s1)
    80001cae:	c12d                	beqz	a0,80001d10 <allocproc+0xb8>
  if((p->alarm_trapframe=(struct trapframe *)kalloc())==0)
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	ed2080e7          	jalr	-302(ra) # 80000b82 <kalloc>
    80001cb8:	892a                	mv	s2,a0
    80001cba:	f0a8                	sd	a0,96(s1)
    80001cbc:	c12d                	beqz	a0,80001d1e <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	e42080e7          	jalr	-446(ra) # 80001b02 <proc_pagetable>
    80001cc8:	892a                	mv	s2,a0
    80001cca:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ccc:	c125                	beqz	a0,80001d2c <allocproc+0xd4>
  memset(&p->context, 0, sizeof(p->context));
    80001cce:	07000613          	li	a2,112
    80001cd2:	4581                	li	a1,0
    80001cd4:	07048513          	addi	a0,s1,112
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	096080e7          	jalr	150(ra) # 80000d6e <memset>
  p->context.ra = (uint64)forkret;
    80001ce0:	00000797          	auipc	a5,0x0
    80001ce4:	d9678793          	addi	a5,a5,-618 # 80001a76 <forkret>
    80001ce8:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cea:	60bc                	ld	a5,64(s1)
    80001cec:	6705                	lui	a4,0x1
    80001cee:	97ba                	add	a5,a5,a4
    80001cf0:	fcbc                	sd	a5,120(s1)
  p->ticks=0;
    80001cf2:	1604ac23          	sw	zero,376(s1)
  p->ticknum=0;
    80001cf6:	1604ae23          	sw	zero,380(s1)
  p->handler=0;  
    80001cfa:	1804b023          	sd	zero,384(s1)
  p->alarm_lock=0;
    80001cfe:	0604a423          	sw	zero,104(s1)
}
    80001d02:	8526                	mv	a0,s1
    80001d04:	60e2                	ld	ra,24(sp)
    80001d06:	6442                	ld	s0,16(sp)
    80001d08:	64a2                	ld	s1,8(sp)
    80001d0a:	6902                	ld	s2,0(sp)
    80001d0c:	6105                	addi	sp,sp,32
    80001d0e:	8082                	ret
    release(&p->lock);
    80001d10:	8526                	mv	a0,s1
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	014080e7          	jalr	20(ra) # 80000d26 <release>
    return 0;
    80001d1a:	84ca                	mv	s1,s2
    80001d1c:	b7dd                	j	80001d02 <allocproc+0xaa>
    release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	006080e7          	jalr	6(ra) # 80000d26 <release>
    return 0;
    80001d28:	84ca                	mv	s1,s2
    80001d2a:	bfe1                	j	80001d02 <allocproc+0xaa>
    freeproc(p);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	ec2080e7          	jalr	-318(ra) # 80001bf0 <freeproc>
    release(&p->lock);
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	fee080e7          	jalr	-18(ra) # 80000d26 <release>
    return 0;
    80001d40:	84ca                	mv	s1,s2
    80001d42:	b7c1                	j	80001d02 <allocproc+0xaa>

0000000080001d44 <userinit>:
{
    80001d44:	1101                	addi	sp,sp,-32
    80001d46:	ec06                	sd	ra,24(sp)
    80001d48:	e822                	sd	s0,16(sp)
    80001d4a:	e426                	sd	s1,8(sp)
    80001d4c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	f0a080e7          	jalr	-246(ra) # 80001c58 <allocproc>
    80001d56:	84aa                	mv	s1,a0
  initproc = p;
    80001d58:	00007797          	auipc	a5,0x7
    80001d5c:	2ca7b023          	sd	a0,704(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d60:	03400613          	li	a2,52
    80001d64:	00007597          	auipc	a1,0x7
    80001d68:	aec58593          	addi	a1,a1,-1300 # 80008850 <initcode>
    80001d6c:	6928                	ld	a0,80(a0)
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	6b8080e7          	jalr	1720(ra) # 80001426 <uvminit>
  p->sz = PGSIZE;
    80001d76:	6785                	lui	a5,0x1
    80001d78:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d7a:	6cb8                	ld	a4,88(s1)
    80001d7c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d80:	6cb8                	ld	a4,88(s1)
    80001d82:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d84:	4641                	li	a2,16
    80001d86:	00006597          	auipc	a1,0x6
    80001d8a:	47a58593          	addi	a1,a1,1146 # 80008200 <digits+0x1a8>
    80001d8e:	16848513          	addi	a0,s1,360
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	12e080e7          	jalr	302(ra) # 80000ec0 <safestrcpy>
  p->cwd = namei("/");
    80001d9a:	00006517          	auipc	a0,0x6
    80001d9e:	47650513          	addi	a0,a0,1142 # 80008210 <digits+0x1b8>
    80001da2:	00002097          	auipc	ra,0x2
    80001da6:	1f0080e7          	jalr	496(ra) # 80003f92 <namei>
    80001daa:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001dae:	4789                	li	a5,2
    80001db0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	f72080e7          	jalr	-142(ra) # 80000d26 <release>
}
    80001dbc:	60e2                	ld	ra,24(sp)
    80001dbe:	6442                	ld	s0,16(sp)
    80001dc0:	64a2                	ld	s1,8(sp)
    80001dc2:	6105                	addi	sp,sp,32
    80001dc4:	8082                	ret

0000000080001dc6 <growproc>:
{
    80001dc6:	1101                	addi	sp,sp,-32
    80001dc8:	ec06                	sd	ra,24(sp)
    80001dca:	e822                	sd	s0,16(sp)
    80001dcc:	e426                	sd	s1,8(sp)
    80001dce:	e04a                	sd	s2,0(sp)
    80001dd0:	1000                	addi	s0,sp,32
    80001dd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	c6a080e7          	jalr	-918(ra) # 80001a3e <myproc>
    80001ddc:	892a                	mv	s2,a0
  sz = p->sz;
    80001dde:	652c                	ld	a1,72(a0)
    80001de0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001de4:	00904f63          	bgtz	s1,80001e02 <growproc+0x3c>
  } else if(n < 0){
    80001de8:	0204cc63          	bltz	s1,80001e20 <growproc+0x5a>
  p->sz = sz;
    80001dec:	1602                	slli	a2,a2,0x20
    80001dee:	9201                	srli	a2,a2,0x20
    80001df0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001df4:	4501                	li	a0,0
}
    80001df6:	60e2                	ld	ra,24(sp)
    80001df8:	6442                	ld	s0,16(sp)
    80001dfa:	64a2                	ld	s1,8(sp)
    80001dfc:	6902                	ld	s2,0(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e02:	9e25                	addw	a2,a2,s1
    80001e04:	1602                	slli	a2,a2,0x20
    80001e06:	9201                	srli	a2,a2,0x20
    80001e08:	1582                	slli	a1,a1,0x20
    80001e0a:	9181                	srli	a1,a1,0x20
    80001e0c:	6928                	ld	a0,80(a0)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	6d2080e7          	jalr	1746(ra) # 800014e0 <uvmalloc>
    80001e16:	0005061b          	sext.w	a2,a0
    80001e1a:	fa69                	bnez	a2,80001dec <growproc+0x26>
      return -1;
    80001e1c:	557d                	li	a0,-1
    80001e1e:	bfe1                	j	80001df6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e20:	9e25                	addw	a2,a2,s1
    80001e22:	1602                	slli	a2,a2,0x20
    80001e24:	9201                	srli	a2,a2,0x20
    80001e26:	1582                	slli	a1,a1,0x20
    80001e28:	9181                	srli	a1,a1,0x20
    80001e2a:	6928                	ld	a0,80(a0)
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	66c080e7          	jalr	1644(ra) # 80001498 <uvmdealloc>
    80001e34:	0005061b          	sext.w	a2,a0
    80001e38:	bf55                	j	80001dec <growproc+0x26>

0000000080001e3a <fork>:
{
    80001e3a:	7139                	addi	sp,sp,-64
    80001e3c:	fc06                	sd	ra,56(sp)
    80001e3e:	f822                	sd	s0,48(sp)
    80001e40:	f426                	sd	s1,40(sp)
    80001e42:	f04a                	sd	s2,32(sp)
    80001e44:	ec4e                	sd	s3,24(sp)
    80001e46:	e852                	sd	s4,16(sp)
    80001e48:	e456                	sd	s5,8(sp)
    80001e4a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	bf2080e7          	jalr	-1038(ra) # 80001a3e <myproc>
    80001e54:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	e02080e7          	jalr	-510(ra) # 80001c58 <allocproc>
    80001e5e:	c17d                	beqz	a0,80001f44 <fork+0x10a>
    80001e60:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e62:	048ab603          	ld	a2,72(s5)
    80001e66:	692c                	ld	a1,80(a0)
    80001e68:	050ab503          	ld	a0,80(s5)
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	7c0080e7          	jalr	1984(ra) # 8000162c <uvmcopy>
    80001e74:	04054a63          	bltz	a0,80001ec8 <fork+0x8e>
  np->sz = p->sz;
    80001e78:	048ab783          	ld	a5,72(s5)
    80001e7c:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e80:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e84:	058ab683          	ld	a3,88(s5)
    80001e88:	87b6                	mv	a5,a3
    80001e8a:	058a3703          	ld	a4,88(s4)
    80001e8e:	12068693          	addi	a3,a3,288
    80001e92:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e96:	6788                	ld	a0,8(a5)
    80001e98:	6b8c                	ld	a1,16(a5)
    80001e9a:	6f90                	ld	a2,24(a5)
    80001e9c:	01073023          	sd	a6,0(a4)
    80001ea0:	e708                	sd	a0,8(a4)
    80001ea2:	eb0c                	sd	a1,16(a4)
    80001ea4:	ef10                	sd	a2,24(a4)
    80001ea6:	02078793          	addi	a5,a5,32
    80001eaa:	02070713          	addi	a4,a4,32
    80001eae:	fed792e3          	bne	a5,a3,80001e92 <fork+0x58>
  np->trapframe->a0 = 0;
    80001eb2:	058a3783          	ld	a5,88(s4)
    80001eb6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001eba:	0e0a8493          	addi	s1,s5,224
    80001ebe:	0e0a0913          	addi	s2,s4,224
    80001ec2:	160a8993          	addi	s3,s5,352
    80001ec6:	a00d                	j	80001ee8 <fork+0xae>
    freeproc(np);
    80001ec8:	8552                	mv	a0,s4
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	d26080e7          	jalr	-730(ra) # 80001bf0 <freeproc>
    release(&np->lock);
    80001ed2:	8552                	mv	a0,s4
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	e52080e7          	jalr	-430(ra) # 80000d26 <release>
    return -1;
    80001edc:	54fd                	li	s1,-1
    80001ede:	a889                	j	80001f30 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001ee0:	04a1                	addi	s1,s1,8
    80001ee2:	0921                	addi	s2,s2,8
    80001ee4:	01348b63          	beq	s1,s3,80001efa <fork+0xc0>
    if(p->ofile[i])
    80001ee8:	6088                	ld	a0,0(s1)
    80001eea:	d97d                	beqz	a0,80001ee0 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eec:	00002097          	auipc	ra,0x2
    80001ef0:	732080e7          	jalr	1842(ra) # 8000461e <filedup>
    80001ef4:	00a93023          	sd	a0,0(s2)
    80001ef8:	b7e5                	j	80001ee0 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001efa:	160ab503          	ld	a0,352(s5)
    80001efe:	00002097          	auipc	ra,0x2
    80001f02:	8a6080e7          	jalr	-1882(ra) # 800037a4 <idup>
    80001f06:	16aa3023          	sd	a0,352(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f0a:	4641                	li	a2,16
    80001f0c:	168a8593          	addi	a1,s5,360
    80001f10:	168a0513          	addi	a0,s4,360
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	fac080e7          	jalr	-84(ra) # 80000ec0 <safestrcpy>
  pid = np->pid;
    80001f1c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001f20:	4789                	li	a5,2
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dfe080e7          	jalr	-514(ra) # 80000d26 <release>
}
    80001f30:	8526                	mv	a0,s1
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	addi	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	54fd                	li	s1,-1
    80001f46:	b7ed                	j	80001f30 <fork+0xf6>

0000000080001f48 <reparent>:
{
    80001f48:	7179                	addi	sp,sp,-48
    80001f4a:	f406                	sd	ra,40(sp)
    80001f4c:	f022                	sd	s0,32(sp)
    80001f4e:	ec26                	sd	s1,24(sp)
    80001f50:	e84a                	sd	s2,16(sp)
    80001f52:	e44e                	sd	s3,8(sp)
    80001f54:	e052                	sd	s4,0(sp)
    80001f56:	1800                	addi	s0,sp,48
    80001f58:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f5a:	00010497          	auipc	s1,0x10
    80001f5e:	e0e48493          	addi	s1,s1,-498 # 80011d68 <proc>
      pp->parent = initproc;
    80001f62:	00007a17          	auipc	s4,0x7
    80001f66:	0b6a0a13          	addi	s4,s4,182 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f6a:	00016997          	auipc	s3,0x16
    80001f6e:	ffe98993          	addi	s3,s3,-2 # 80017f68 <tickslock>
    80001f72:	a029                	j	80001f7c <reparent+0x34>
    80001f74:	18848493          	addi	s1,s1,392
    80001f78:	03348363          	beq	s1,s3,80001f9e <reparent+0x56>
    if(pp->parent == p){
    80001f7c:	709c                	ld	a5,32(s1)
    80001f7e:	ff279be3          	bne	a5,s2,80001f74 <reparent+0x2c>
      acquire(&pp->lock);
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	cee080e7          	jalr	-786(ra) # 80000c72 <acquire>
      pp->parent = initproc;
    80001f8c:	000a3783          	ld	a5,0(s4)
    80001f90:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d92080e7          	jalr	-622(ra) # 80000d26 <release>
    80001f9c:	bfe1                	j	80001f74 <reparent+0x2c>
}
    80001f9e:	70a2                	ld	ra,40(sp)
    80001fa0:	7402                	ld	s0,32(sp)
    80001fa2:	64e2                	ld	s1,24(sp)
    80001fa4:	6942                	ld	s2,16(sp)
    80001fa6:	69a2                	ld	s3,8(sp)
    80001fa8:	6a02                	ld	s4,0(sp)
    80001faa:	6145                	addi	sp,sp,48
    80001fac:	8082                	ret

0000000080001fae <scheduler>:
{
    80001fae:	715d                	addi	sp,sp,-80
    80001fb0:	e486                	sd	ra,72(sp)
    80001fb2:	e0a2                	sd	s0,64(sp)
    80001fb4:	fc26                	sd	s1,56(sp)
    80001fb6:	f84a                	sd	s2,48(sp)
    80001fb8:	f44e                	sd	s3,40(sp)
    80001fba:	f052                	sd	s4,32(sp)
    80001fbc:	ec56                	sd	s5,24(sp)
    80001fbe:	e85a                	sd	s6,16(sp)
    80001fc0:	e45e                	sd	s7,8(sp)
    80001fc2:	e062                	sd	s8,0(sp)
    80001fc4:	0880                	addi	s0,sp,80
    80001fc6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fc8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fca:	00779b13          	slli	s6,a5,0x7
    80001fce:	00010717          	auipc	a4,0x10
    80001fd2:	98270713          	addi	a4,a4,-1662 # 80011950 <pid_lock>
    80001fd6:	975a                	add	a4,a4,s6
    80001fd8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fdc:	00010717          	auipc	a4,0x10
    80001fe0:	99470713          	addi	a4,a4,-1644 # 80011970 <cpus+0x8>
    80001fe4:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fe6:	4c0d                	li	s8,3
        c->proc = p;
    80001fe8:	079e                	slli	a5,a5,0x7
    80001fea:	00010a17          	auipc	s4,0x10
    80001fee:	966a0a13          	addi	s4,s4,-1690 # 80011950 <pid_lock>
    80001ff2:	9a3e                	add	s4,s4,a5
        found = 1;
    80001ff4:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff6:	00016997          	auipc	s3,0x16
    80001ffa:	f7298993          	addi	s3,s3,-142 # 80017f68 <tickslock>
    80001ffe:	a899                	j	80002054 <scheduler+0xa6>
      release(&p->lock);
    80002000:	8526                	mv	a0,s1
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	d24080e7          	jalr	-732(ra) # 80000d26 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200a:	18848493          	addi	s1,s1,392
    8000200e:	03348963          	beq	s1,s3,80002040 <scheduler+0x92>
      acquire(&p->lock);
    80002012:	8526                	mv	a0,s1
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	c5e080e7          	jalr	-930(ra) # 80000c72 <acquire>
      if(p->state == RUNNABLE) {
    8000201c:	4c9c                	lw	a5,24(s1)
    8000201e:	ff2791e3          	bne	a5,s2,80002000 <scheduler+0x52>
        p->state = RUNNING;
    80002022:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002026:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    8000202a:	07048593          	addi	a1,s1,112
    8000202e:	855a                	mv	a0,s6
    80002030:	00000097          	auipc	ra,0x0
    80002034:	60e080e7          	jalr	1550(ra) # 8000263e <swtch>
        c->proc = 0;
    80002038:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000203c:	8ade                	mv	s5,s7
    8000203e:	b7c9                	j	80002000 <scheduler+0x52>
    if(found == 0) {
    80002040:	000a9a63          	bnez	s5,80002054 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002044:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002048:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000204c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002050:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002054:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002058:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000205c:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002060:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002062:	00010497          	auipc	s1,0x10
    80002066:	d0648493          	addi	s1,s1,-762 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000206a:	4909                	li	s2,2
    8000206c:	b75d                	j	80002012 <scheduler+0x64>

000000008000206e <sched>:
{
    8000206e:	7179                	addi	sp,sp,-48
    80002070:	f406                	sd	ra,40(sp)
    80002072:	f022                	sd	s0,32(sp)
    80002074:	ec26                	sd	s1,24(sp)
    80002076:	e84a                	sd	s2,16(sp)
    80002078:	e44e                	sd	s3,8(sp)
    8000207a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	9c2080e7          	jalr	-1598(ra) # 80001a3e <myproc>
    80002084:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b72080e7          	jalr	-1166(ra) # 80000bf8 <holding>
    8000208e:	c93d                	beqz	a0,80002104 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	00010717          	auipc	a4,0x10
    8000209a:	8ba70713          	addi	a4,a4,-1862 # 80011950 <pid_lock>
    8000209e:	97ba                	add	a5,a5,a4
    800020a0:	0907a703          	lw	a4,144(a5)
    800020a4:	4785                	li	a5,1
    800020a6:	06f71763          	bne	a4,a5,80002114 <sched+0xa6>
  if(p->state == RUNNING)
    800020aa:	4c98                	lw	a4,24(s1)
    800020ac:	478d                	li	a5,3
    800020ae:	06f70b63          	beq	a4,a5,80002124 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b8:	efb5                	bnez	a5,80002134 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020bc:	00010917          	auipc	s2,0x10
    800020c0:	89490913          	addi	s2,s2,-1900 # 80011950 <pid_lock>
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	97ca                	add	a5,a5,s2
    800020ca:	0947a983          	lw	s3,148(a5)
    800020ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	00010597          	auipc	a1,0x10
    800020d8:	89c58593          	addi	a1,a1,-1892 # 80011970 <cpus+0x8>
    800020dc:	95be                	add	a1,a1,a5
    800020de:	07048513          	addi	a0,s1,112
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	55c080e7          	jalr	1372(ra) # 8000263e <swtch>
    800020ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	97ca                	add	a5,a5,s2
    800020f2:	0937aa23          	sw	s3,148(a5)
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret
    panic("sched p->lock");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	11450513          	addi	a0,a0,276 # 80008218 <digits+0x1c0>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	4d4080e7          	jalr	1236(ra) # 800005e0 <panic>
    panic("sched locks");
    80002114:	00006517          	auipc	a0,0x6
    80002118:	11450513          	addi	a0,a0,276 # 80008228 <digits+0x1d0>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	4c4080e7          	jalr	1220(ra) # 800005e0 <panic>
    panic("sched running");
    80002124:	00006517          	auipc	a0,0x6
    80002128:	11450513          	addi	a0,a0,276 # 80008238 <digits+0x1e0>
    8000212c:	ffffe097          	auipc	ra,0xffffe
    80002130:	4b4080e7          	jalr	1204(ra) # 800005e0 <panic>
    panic("sched interruptible");
    80002134:	00006517          	auipc	a0,0x6
    80002138:	11450513          	addi	a0,a0,276 # 80008248 <digits+0x1f0>
    8000213c:	ffffe097          	auipc	ra,0xffffe
    80002140:	4a4080e7          	jalr	1188(ra) # 800005e0 <panic>

0000000080002144 <exit>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	e052                	sd	s4,0(sp)
    80002152:	1800                	addi	s0,sp,48
    80002154:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	8e8080e7          	jalr	-1816(ra) # 80001a3e <myproc>
    8000215e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002160:	00007797          	auipc	a5,0x7
    80002164:	eb87b783          	ld	a5,-328(a5) # 80009018 <initproc>
    80002168:	0e050493          	addi	s1,a0,224
    8000216c:	16050913          	addi	s2,a0,352
    80002170:	02a79363          	bne	a5,a0,80002196 <exit+0x52>
    panic("init exiting");
    80002174:	00006517          	auipc	a0,0x6
    80002178:	0ec50513          	addi	a0,a0,236 # 80008260 <digits+0x208>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	464080e7          	jalr	1124(ra) # 800005e0 <panic>
      fileclose(f);
    80002184:	00002097          	auipc	ra,0x2
    80002188:	4ec080e7          	jalr	1260(ra) # 80004670 <fileclose>
      p->ofile[fd] = 0;
    8000218c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002190:	04a1                	addi	s1,s1,8
    80002192:	01248563          	beq	s1,s2,8000219c <exit+0x58>
    if(p->ofile[fd]){
    80002196:	6088                	ld	a0,0(s1)
    80002198:	f575                	bnez	a0,80002184 <exit+0x40>
    8000219a:	bfdd                	j	80002190 <exit+0x4c>
  begin_op();
    8000219c:	00002097          	auipc	ra,0x2
    800021a0:	002080e7          	jalr	2(ra) # 8000419e <begin_op>
  iput(p->cwd);
    800021a4:	1609b503          	ld	a0,352(s3)
    800021a8:	00001097          	auipc	ra,0x1
    800021ac:	7f4080e7          	jalr	2036(ra) # 8000399c <iput>
  end_op();
    800021b0:	00002097          	auipc	ra,0x2
    800021b4:	06e080e7          	jalr	110(ra) # 8000421e <end_op>
  p->cwd = 0;
    800021b8:	1609b023          	sd	zero,352(s3)
  acquire(&initproc->lock);
    800021bc:	00007497          	auipc	s1,0x7
    800021c0:	e5c48493          	addi	s1,s1,-420 # 80009018 <initproc>
    800021c4:	6088                	ld	a0,0(s1)
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	aac080e7          	jalr	-1364(ra) # 80000c72 <acquire>
  wakeup1(initproc);
    800021ce:	6088                	ld	a0,0(s1)
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	72e080e7          	jalr	1838(ra) # 800018fe <wakeup1>
  release(&initproc->lock);
    800021d8:	6088                	ld	a0,0(s1)
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	b4c080e7          	jalr	-1204(ra) # 80000d26 <release>
  acquire(&p->lock);
    800021e2:	854e                	mv	a0,s3
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	a8e080e7          	jalr	-1394(ra) # 80000c72 <acquire>
  struct proc *original_parent = p->parent;
    800021ec:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021f0:	854e                	mv	a0,s3
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	b34080e7          	jalr	-1228(ra) # 80000d26 <release>
  acquire(&original_parent->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a76080e7          	jalr	-1418(ra) # 80000c72 <acquire>
  acquire(&p->lock);
    80002204:	854e                	mv	a0,s3
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a6c080e7          	jalr	-1428(ra) # 80000c72 <acquire>
  reparent(p);
    8000220e:	854e                	mv	a0,s3
    80002210:	00000097          	auipc	ra,0x0
    80002214:	d38080e7          	jalr	-712(ra) # 80001f48 <reparent>
  wakeup1(original_parent);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	6e4080e7          	jalr	1764(ra) # 800018fe <wakeup1>
  p->xstate = status;
    80002222:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002226:	4791                	li	a5,4
    80002228:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	af8080e7          	jalr	-1288(ra) # 80000d26 <release>
  sched();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e38080e7          	jalr	-456(ra) # 8000206e <sched>
  panic("zombie exit");
    8000223e:	00006517          	auipc	a0,0x6
    80002242:	03250513          	addi	a0,a0,50 # 80008270 <digits+0x218>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	39a080e7          	jalr	922(ra) # 800005e0 <panic>

000000008000224e <yield>:
{
    8000224e:	1101                	addi	sp,sp,-32
    80002250:	ec06                	sd	ra,24(sp)
    80002252:	e822                	sd	s0,16(sp)
    80002254:	e426                	sd	s1,8(sp)
    80002256:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	7e6080e7          	jalr	2022(ra) # 80001a3e <myproc>
    80002260:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	a10080e7          	jalr	-1520(ra) # 80000c72 <acquire>
  p->state = RUNNABLE;
    8000226a:	4789                	li	a5,2
    8000226c:	cc9c                	sw	a5,24(s1)
  sched();
    8000226e:	00000097          	auipc	ra,0x0
    80002272:	e00080e7          	jalr	-512(ra) # 8000206e <sched>
  release(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	aae080e7          	jalr	-1362(ra) # 80000d26 <release>
}
    80002280:	60e2                	ld	ra,24(sp)
    80002282:	6442                	ld	s0,16(sp)
    80002284:	64a2                	ld	s1,8(sp)
    80002286:	6105                	addi	sp,sp,32
    80002288:	8082                	ret

000000008000228a <sleep>:
{
    8000228a:	7179                	addi	sp,sp,-48
    8000228c:	f406                	sd	ra,40(sp)
    8000228e:	f022                	sd	s0,32(sp)
    80002290:	ec26                	sd	s1,24(sp)
    80002292:	e84a                	sd	s2,16(sp)
    80002294:	e44e                	sd	s3,8(sp)
    80002296:	1800                	addi	s0,sp,48
    80002298:	89aa                	mv	s3,a0
    8000229a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	7a2080e7          	jalr	1954(ra) # 80001a3e <myproc>
    800022a4:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022a6:	05250663          	beq	a0,s2,800022f2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9c8080e7          	jalr	-1592(ra) # 80000c72 <acquire>
    release(lk);
    800022b2:	854a                	mv	a0,s2
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	a72080e7          	jalr	-1422(ra) # 80000d26 <release>
  p->chan = chan;
    800022bc:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022c0:	4785                	li	a5,1
    800022c2:	cc9c                	sw	a5,24(s1)
  sched();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	daa080e7          	jalr	-598(ra) # 8000206e <sched>
  p->chan = 0;
    800022cc:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	a54080e7          	jalr	-1452(ra) # 80000d26 <release>
    acquire(lk);
    800022da:	854a                	mv	a0,s2
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	996080e7          	jalr	-1642(ra) # 80000c72 <acquire>
}
    800022e4:	70a2                	ld	ra,40(sp)
    800022e6:	7402                	ld	s0,32(sp)
    800022e8:	64e2                	ld	s1,24(sp)
    800022ea:	6942                	ld	s2,16(sp)
    800022ec:	69a2                	ld	s3,8(sp)
    800022ee:	6145                	addi	sp,sp,48
    800022f0:	8082                	ret
  p->chan = chan;
    800022f2:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022f6:	4785                	li	a5,1
    800022f8:	cd1c                	sw	a5,24(a0)
  sched();
    800022fa:	00000097          	auipc	ra,0x0
    800022fe:	d74080e7          	jalr	-652(ra) # 8000206e <sched>
  p->chan = 0;
    80002302:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002306:	bff9                	j	800022e4 <sleep+0x5a>

0000000080002308 <wait>:
{
    80002308:	715d                	addi	sp,sp,-80
    8000230a:	e486                	sd	ra,72(sp)
    8000230c:	e0a2                	sd	s0,64(sp)
    8000230e:	fc26                	sd	s1,56(sp)
    80002310:	f84a                	sd	s2,48(sp)
    80002312:	f44e                	sd	s3,40(sp)
    80002314:	f052                	sd	s4,32(sp)
    80002316:	ec56                	sd	s5,24(sp)
    80002318:	e85a                	sd	s6,16(sp)
    8000231a:	e45e                	sd	s7,8(sp)
    8000231c:	0880                	addi	s0,sp,80
    8000231e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	71e080e7          	jalr	1822(ra) # 80001a3e <myproc>
    80002328:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	948080e7          	jalr	-1720(ra) # 80000c72 <acquire>
    havekids = 0;
    80002332:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002334:	4a11                	li	s4,4
        havekids = 1;
    80002336:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002338:	00016997          	auipc	s3,0x16
    8000233c:	c3098993          	addi	s3,s3,-976 # 80017f68 <tickslock>
    havekids = 0;
    80002340:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002342:	00010497          	auipc	s1,0x10
    80002346:	a2648493          	addi	s1,s1,-1498 # 80011d68 <proc>
    8000234a:	a08d                	j	800023ac <wait+0xa4>
          pid = np->pid;
    8000234c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002350:	000b0e63          	beqz	s6,8000236c <wait+0x64>
    80002354:	4691                	li	a3,4
    80002356:	03448613          	addi	a2,s1,52
    8000235a:	85da                	mv	a1,s6
    8000235c:	05093503          	ld	a0,80(s2)
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	3d0080e7          	jalr	976(ra) # 80001730 <copyout>
    80002368:	02054263          	bltz	a0,8000238c <wait+0x84>
          freeproc(np);
    8000236c:	8526                	mv	a0,s1
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	882080e7          	jalr	-1918(ra) # 80001bf0 <freeproc>
          release(&np->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	9ae080e7          	jalr	-1618(ra) # 80000d26 <release>
          release(&p->lock);
    80002380:	854a                	mv	a0,s2
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	9a4080e7          	jalr	-1628(ra) # 80000d26 <release>
          return pid;
    8000238a:	a8a9                	j	800023e4 <wait+0xdc>
            release(&np->lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	998080e7          	jalr	-1640(ra) # 80000d26 <release>
            release(&p->lock);
    80002396:	854a                	mv	a0,s2
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	98e080e7          	jalr	-1650(ra) # 80000d26 <release>
            return -1;
    800023a0:	59fd                	li	s3,-1
    800023a2:	a089                	j	800023e4 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800023a4:	18848493          	addi	s1,s1,392
    800023a8:	03348463          	beq	s1,s3,800023d0 <wait+0xc8>
      if(np->parent == p){
    800023ac:	709c                	ld	a5,32(s1)
    800023ae:	ff279be3          	bne	a5,s2,800023a4 <wait+0x9c>
        acquire(&np->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8be080e7          	jalr	-1858(ra) # 80000c72 <acquire>
        if(np->state == ZOMBIE){
    800023bc:	4c9c                	lw	a5,24(s1)
    800023be:	f94787e3          	beq	a5,s4,8000234c <wait+0x44>
        release(&np->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	962080e7          	jalr	-1694(ra) # 80000d26 <release>
        havekids = 1;
    800023cc:	8756                	mv	a4,s5
    800023ce:	bfd9                	j	800023a4 <wait+0x9c>
    if(!havekids || p->killed){
    800023d0:	c701                	beqz	a4,800023d8 <wait+0xd0>
    800023d2:	03092783          	lw	a5,48(s2)
    800023d6:	c39d                	beqz	a5,800023fc <wait+0xf4>
      release(&p->lock);
    800023d8:	854a                	mv	a0,s2
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	94c080e7          	jalr	-1716(ra) # 80000d26 <release>
      return -1;
    800023e2:	59fd                	li	s3,-1
}
    800023e4:	854e                	mv	a0,s3
    800023e6:	60a6                	ld	ra,72(sp)
    800023e8:	6406                	ld	s0,64(sp)
    800023ea:	74e2                	ld	s1,56(sp)
    800023ec:	7942                	ld	s2,48(sp)
    800023ee:	79a2                	ld	s3,40(sp)
    800023f0:	7a02                	ld	s4,32(sp)
    800023f2:	6ae2                	ld	s5,24(sp)
    800023f4:	6b42                	ld	s6,16(sp)
    800023f6:	6ba2                	ld	s7,8(sp)
    800023f8:	6161                	addi	sp,sp,80
    800023fa:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023fc:	85ca                	mv	a1,s2
    800023fe:	854a                	mv	a0,s2
    80002400:	00000097          	auipc	ra,0x0
    80002404:	e8a080e7          	jalr	-374(ra) # 8000228a <sleep>
    havekids = 0;
    80002408:	bf25                	j	80002340 <wait+0x38>

000000008000240a <wakeup>:
{
    8000240a:	7139                	addi	sp,sp,-64
    8000240c:	fc06                	sd	ra,56(sp)
    8000240e:	f822                	sd	s0,48(sp)
    80002410:	f426                	sd	s1,40(sp)
    80002412:	f04a                	sd	s2,32(sp)
    80002414:	ec4e                	sd	s3,24(sp)
    80002416:	e852                	sd	s4,16(sp)
    80002418:	e456                	sd	s5,8(sp)
    8000241a:	0080                	addi	s0,sp,64
    8000241c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241e:	00010497          	auipc	s1,0x10
    80002422:	94a48493          	addi	s1,s1,-1718 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002426:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002428:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242a:	00016917          	auipc	s2,0x16
    8000242e:	b3e90913          	addi	s2,s2,-1218 # 80017f68 <tickslock>
    80002432:	a811                	j	80002446 <wakeup+0x3c>
    release(&p->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	8f0080e7          	jalr	-1808(ra) # 80000d26 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000243e:	18848493          	addi	s1,s1,392
    80002442:	03248063          	beq	s1,s2,80002462 <wakeup+0x58>
    acquire(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	82a080e7          	jalr	-2006(ra) # 80000c72 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002450:	4c9c                	lw	a5,24(s1)
    80002452:	ff3791e3          	bne	a5,s3,80002434 <wakeup+0x2a>
    80002456:	749c                	ld	a5,40(s1)
    80002458:	fd479ee3          	bne	a5,s4,80002434 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000245c:	0154ac23          	sw	s5,24(s1)
    80002460:	bfd1                	j	80002434 <wakeup+0x2a>
}
    80002462:	70e2                	ld	ra,56(sp)
    80002464:	7442                	ld	s0,48(sp)
    80002466:	74a2                	ld	s1,40(sp)
    80002468:	7902                	ld	s2,32(sp)
    8000246a:	69e2                	ld	s3,24(sp)
    8000246c:	6a42                	ld	s4,16(sp)
    8000246e:	6aa2                	ld	s5,8(sp)
    80002470:	6121                	addi	sp,sp,64
    80002472:	8082                	ret

0000000080002474 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002474:	7179                	addi	sp,sp,-48
    80002476:	f406                	sd	ra,40(sp)
    80002478:	f022                	sd	s0,32(sp)
    8000247a:	ec26                	sd	s1,24(sp)
    8000247c:	e84a                	sd	s2,16(sp)
    8000247e:	e44e                	sd	s3,8(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002484:	00010497          	auipc	s1,0x10
    80002488:	8e448493          	addi	s1,s1,-1820 # 80011d68 <proc>
    8000248c:	00016997          	auipc	s3,0x16
    80002490:	adc98993          	addi	s3,s3,-1316 # 80017f68 <tickslock>
    acquire(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	7dc080e7          	jalr	2012(ra) # 80000c72 <acquire>
    if(p->pid == pid){
    8000249e:	5c9c                	lw	a5,56(s1)
    800024a0:	01278d63          	beq	a5,s2,800024ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024a4:	8526                	mv	a0,s1
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	880080e7          	jalr	-1920(ra) # 80000d26 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ae:	18848493          	addi	s1,s1,392
    800024b2:	ff3491e3          	bne	s1,s3,80002494 <kill+0x20>
  }
  return -1;
    800024b6:	557d                	li	a0,-1
    800024b8:	a821                	j	800024d0 <kill+0x5c>
      p->killed = 1;
    800024ba:	4785                	li	a5,1
    800024bc:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024be:	4c98                	lw	a4,24(s1)
    800024c0:	00f70f63          	beq	a4,a5,800024de <kill+0x6a>
      release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	860080e7          	jalr	-1952(ra) # 80000d26 <release>
      return 0;
    800024ce:	4501                	li	a0,0
}
    800024d0:	70a2                	ld	ra,40(sp)
    800024d2:	7402                	ld	s0,32(sp)
    800024d4:	64e2                	ld	s1,24(sp)
    800024d6:	6942                	ld	s2,16(sp)
    800024d8:	69a2                	ld	s3,8(sp)
    800024da:	6145                	addi	sp,sp,48
    800024dc:	8082                	ret
        p->state = RUNNABLE;
    800024de:	4789                	li	a5,2
    800024e0:	cc9c                	sw	a5,24(s1)
    800024e2:	b7cd                	j	800024c4 <kill+0x50>

00000000800024e4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024e4:	7179                	addi	sp,sp,-48
    800024e6:	f406                	sd	ra,40(sp)
    800024e8:	f022                	sd	s0,32(sp)
    800024ea:	ec26                	sd	s1,24(sp)
    800024ec:	e84a                	sd	s2,16(sp)
    800024ee:	e44e                	sd	s3,8(sp)
    800024f0:	e052                	sd	s4,0(sp)
    800024f2:	1800                	addi	s0,sp,48
    800024f4:	84aa                	mv	s1,a0
    800024f6:	892e                	mv	s2,a1
    800024f8:	89b2                	mv	s3,a2
    800024fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	542080e7          	jalr	1346(ra) # 80001a3e <myproc>
  if(user_dst){
    80002504:	c08d                	beqz	s1,80002526 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002506:	86d2                	mv	a3,s4
    80002508:	864e                	mv	a2,s3
    8000250a:	85ca                	mv	a1,s2
    8000250c:	6928                	ld	a0,80(a0)
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	222080e7          	jalr	546(ra) # 80001730 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002516:	70a2                	ld	ra,40(sp)
    80002518:	7402                	ld	s0,32(sp)
    8000251a:	64e2                	ld	s1,24(sp)
    8000251c:	6942                	ld	s2,16(sp)
    8000251e:	69a2                	ld	s3,8(sp)
    80002520:	6a02                	ld	s4,0(sp)
    80002522:	6145                	addi	sp,sp,48
    80002524:	8082                	ret
    memmove((char *)dst, src, len);
    80002526:	000a061b          	sext.w	a2,s4
    8000252a:	85ce                	mv	a1,s3
    8000252c:	854a                	mv	a0,s2
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	89c080e7          	jalr	-1892(ra) # 80000dca <memmove>
    return 0;
    80002536:	8526                	mv	a0,s1
    80002538:	bff9                	j	80002516 <either_copyout+0x32>

000000008000253a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000253a:	7179                	addi	sp,sp,-48
    8000253c:	f406                	sd	ra,40(sp)
    8000253e:	f022                	sd	s0,32(sp)
    80002540:	ec26                	sd	s1,24(sp)
    80002542:	e84a                	sd	s2,16(sp)
    80002544:	e44e                	sd	s3,8(sp)
    80002546:	e052                	sd	s4,0(sp)
    80002548:	1800                	addi	s0,sp,48
    8000254a:	892a                	mv	s2,a0
    8000254c:	84ae                	mv	s1,a1
    8000254e:	89b2                	mv	s3,a2
    80002550:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	4ec080e7          	jalr	1260(ra) # 80001a3e <myproc>
  if(user_src){
    8000255a:	c08d                	beqz	s1,8000257c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000255c:	86d2                	mv	a3,s4
    8000255e:	864e                	mv	a2,s3
    80002560:	85ca                	mv	a1,s2
    80002562:	6928                	ld	a0,80(a0)
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	258080e7          	jalr	600(ra) # 800017bc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000256c:	70a2                	ld	ra,40(sp)
    8000256e:	7402                	ld	s0,32(sp)
    80002570:	64e2                	ld	s1,24(sp)
    80002572:	6942                	ld	s2,16(sp)
    80002574:	69a2                	ld	s3,8(sp)
    80002576:	6a02                	ld	s4,0(sp)
    80002578:	6145                	addi	sp,sp,48
    8000257a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000257c:	000a061b          	sext.w	a2,s4
    80002580:	85ce                	mv	a1,s3
    80002582:	854a                	mv	a0,s2
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	846080e7          	jalr	-1978(ra) # 80000dca <memmove>
    return 0;
    8000258c:	8526                	mv	a0,s1
    8000258e:	bff9                	j	8000256c <either_copyin+0x32>

0000000080002590 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002590:	715d                	addi	sp,sp,-80
    80002592:	e486                	sd	ra,72(sp)
    80002594:	e0a2                	sd	s0,64(sp)
    80002596:	fc26                	sd	s1,56(sp)
    80002598:	f84a                	sd	s2,48(sp)
    8000259a:	f44e                	sd	s3,40(sp)
    8000259c:	f052                	sd	s4,32(sp)
    8000259e:	ec56                	sd	s5,24(sp)
    800025a0:	e85a                	sd	s6,16(sp)
    800025a2:	e45e                	sd	s7,8(sp)
    800025a4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025a6:	00006517          	auipc	a0,0x6
    800025aa:	b3a50513          	addi	a0,a0,-1222 # 800080e0 <digits+0x88>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	084080e7          	jalr	132(ra) # 80000632 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b6:	00010497          	auipc	s1,0x10
    800025ba:	91a48493          	addi	s1,s1,-1766 # 80011ed0 <proc+0x168>
    800025be:	00016917          	auipc	s2,0x16
    800025c2:	b1290913          	addi	s2,s2,-1262 # 800180d0 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c6:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025c8:	00006997          	auipc	s3,0x6
    800025cc:	cb898993          	addi	s3,s3,-840 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025d0:	00006a97          	auipc	s5,0x6
    800025d4:	cb8a8a93          	addi	s5,s5,-840 # 80008288 <digits+0x230>
    printf("\n");
    800025d8:	00006a17          	auipc	s4,0x6
    800025dc:	b08a0a13          	addi	s4,s4,-1272 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e0:	00006b97          	auipc	s7,0x6
    800025e4:	ce0b8b93          	addi	s7,s7,-800 # 800082c0 <states.0>
    800025e8:	a00d                	j	8000260a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ea:	ed06a583          	lw	a1,-304(a3)
    800025ee:	8556                	mv	a0,s5
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	042080e7          	jalr	66(ra) # 80000632 <printf>
    printf("\n");
    800025f8:	8552                	mv	a0,s4
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	038080e7          	jalr	56(ra) # 80000632 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002602:	18848493          	addi	s1,s1,392
    80002606:	03248163          	beq	s1,s2,80002628 <procdump+0x98>
    if(p->state == UNUSED)
    8000260a:	86a6                	mv	a3,s1
    8000260c:	eb04a783          	lw	a5,-336(s1)
    80002610:	dbed                	beqz	a5,80002602 <procdump+0x72>
      state = "???";
    80002612:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002614:	fcfb6be3          	bltu	s6,a5,800025ea <procdump+0x5a>
    80002618:	1782                	slli	a5,a5,0x20
    8000261a:	9381                	srli	a5,a5,0x20
    8000261c:	078e                	slli	a5,a5,0x3
    8000261e:	97de                	add	a5,a5,s7
    80002620:	6390                	ld	a2,0(a5)
    80002622:	f661                	bnez	a2,800025ea <procdump+0x5a>
      state = "???";
    80002624:	864e                	mv	a2,s3
    80002626:	b7d1                	j	800025ea <procdump+0x5a>
  }
}
    80002628:	60a6                	ld	ra,72(sp)
    8000262a:	6406                	ld	s0,64(sp)
    8000262c:	74e2                	ld	s1,56(sp)
    8000262e:	7942                	ld	s2,48(sp)
    80002630:	79a2                	ld	s3,40(sp)
    80002632:	7a02                	ld	s4,32(sp)
    80002634:	6ae2                	ld	s5,24(sp)
    80002636:	6b42                	ld	s6,16(sp)
    80002638:	6ba2                	ld	s7,8(sp)
    8000263a:	6161                	addi	sp,sp,80
    8000263c:	8082                	ret

000000008000263e <swtch>:
    8000263e:	00153023          	sd	ra,0(a0)
    80002642:	00253423          	sd	sp,8(a0)
    80002646:	e900                	sd	s0,16(a0)
    80002648:	ed04                	sd	s1,24(a0)
    8000264a:	03253023          	sd	s2,32(a0)
    8000264e:	03353423          	sd	s3,40(a0)
    80002652:	03453823          	sd	s4,48(a0)
    80002656:	03553c23          	sd	s5,56(a0)
    8000265a:	05653023          	sd	s6,64(a0)
    8000265e:	05753423          	sd	s7,72(a0)
    80002662:	05853823          	sd	s8,80(a0)
    80002666:	05953c23          	sd	s9,88(a0)
    8000266a:	07a53023          	sd	s10,96(a0)
    8000266e:	07b53423          	sd	s11,104(a0)
    80002672:	0005b083          	ld	ra,0(a1)
    80002676:	0085b103          	ld	sp,8(a1)
    8000267a:	6980                	ld	s0,16(a1)
    8000267c:	6d84                	ld	s1,24(a1)
    8000267e:	0205b903          	ld	s2,32(a1)
    80002682:	0285b983          	ld	s3,40(a1)
    80002686:	0305ba03          	ld	s4,48(a1)
    8000268a:	0385ba83          	ld	s5,56(a1)
    8000268e:	0405bb03          	ld	s6,64(a1)
    80002692:	0485bb83          	ld	s7,72(a1)
    80002696:	0505bc03          	ld	s8,80(a1)
    8000269a:	0585bc83          	ld	s9,88(a1)
    8000269e:	0605bd03          	ld	s10,96(a1)
    800026a2:	0685bd83          	ld	s11,104(a1)
    800026a6:	8082                	ret

00000000800026a8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026a8:	1141                	addi	sp,sp,-16
    800026aa:	e406                	sd	ra,8(sp)
    800026ac:	e022                	sd	s0,0(sp)
    800026ae:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026b0:	00006597          	auipc	a1,0x6
    800026b4:	c3858593          	addi	a1,a1,-968 # 800082e8 <states.0+0x28>
    800026b8:	00016517          	auipc	a0,0x16
    800026bc:	8b050513          	addi	a0,a0,-1872 # 80017f68 <tickslock>
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	522080e7          	jalr	1314(ra) # 80000be2 <initlock>
}
    800026c8:	60a2                	ld	ra,8(sp)
    800026ca:	6402                	ld	s0,0(sp)
    800026cc:	0141                	addi	sp,sp,16
    800026ce:	8082                	ret

00000000800026d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026d0:	1141                	addi	sp,sp,-16
    800026d2:	e422                	sd	s0,8(sp)
    800026d4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d6:	00003797          	auipc	a5,0x3
    800026da:	5fa78793          	addi	a5,a5,1530 # 80005cd0 <kernelvec>
    800026de:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026e2:	6422                	ld	s0,8(sp)
    800026e4:	0141                	addi	sp,sp,16
    800026e6:	8082                	ret

00000000800026e8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026e8:	1141                	addi	sp,sp,-16
    800026ea:	e406                	sd	ra,8(sp)
    800026ec:	e022                	sd	s0,0(sp)
    800026ee:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026f0:	fffff097          	auipc	ra,0xfffff
    800026f4:	34e080e7          	jalr	846(ra) # 80001a3e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026fc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026fe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002702:	00005617          	auipc	a2,0x5
    80002706:	8fe60613          	addi	a2,a2,-1794 # 80007000 <_trampoline>
    8000270a:	00005697          	auipc	a3,0x5
    8000270e:	8f668693          	addi	a3,a3,-1802 # 80007000 <_trampoline>
    80002712:	8e91                	sub	a3,a3,a2
    80002714:	040007b7          	lui	a5,0x4000
    80002718:	17fd                	addi	a5,a5,-1
    8000271a:	07b2                	slli	a5,a5,0xc
    8000271c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000271e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002722:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002724:	180026f3          	csrr	a3,satp
    80002728:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000272a:	6d38                	ld	a4,88(a0)
    8000272c:	6134                	ld	a3,64(a0)
    8000272e:	6585                	lui	a1,0x1
    80002730:	96ae                	add	a3,a3,a1
    80002732:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002734:	6d38                	ld	a4,88(a0)
    80002736:	00000697          	auipc	a3,0x0
    8000273a:	13868693          	addi	a3,a3,312 # 8000286e <usertrap>
    8000273e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002740:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002742:	8692                	mv	a3,tp
    80002744:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002746:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000274a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000274e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002752:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002756:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002758:	6f18                	ld	a4,24(a4)
    8000275a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000275e:	692c                	ld	a1,80(a0)
    80002760:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002762:	00005717          	auipc	a4,0x5
    80002766:	92e70713          	addi	a4,a4,-1746 # 80007090 <userret>
    8000276a:	8f11                	sub	a4,a4,a2
    8000276c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000276e:	577d                	li	a4,-1
    80002770:	177e                	slli	a4,a4,0x3f
    80002772:	8dd9                	or	a1,a1,a4
    80002774:	02000537          	lui	a0,0x2000
    80002778:	157d                	addi	a0,a0,-1
    8000277a:	0536                	slli	a0,a0,0xd
    8000277c:	9782                	jalr	a5
}
    8000277e:	60a2                	ld	ra,8(sp)
    80002780:	6402                	ld	s0,0(sp)
    80002782:	0141                	addi	sp,sp,16
    80002784:	8082                	ret

0000000080002786 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002786:	1101                	addi	sp,sp,-32
    80002788:	ec06                	sd	ra,24(sp)
    8000278a:	e822                	sd	s0,16(sp)
    8000278c:	e426                	sd	s1,8(sp)
    8000278e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002790:	00015497          	auipc	s1,0x15
    80002794:	7d848493          	addi	s1,s1,2008 # 80017f68 <tickslock>
    80002798:	8526                	mv	a0,s1
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	4d8080e7          	jalr	1240(ra) # 80000c72 <acquire>
  ticks++;
    800027a2:	00007517          	auipc	a0,0x7
    800027a6:	87e50513          	addi	a0,a0,-1922 # 80009020 <ticks>
    800027aa:	411c                	lw	a5,0(a0)
    800027ac:	2785                	addiw	a5,a5,1
    800027ae:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027b0:	00000097          	auipc	ra,0x0
    800027b4:	c5a080e7          	jalr	-934(ra) # 8000240a <wakeup>
  release(&tickslock);
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	56c080e7          	jalr	1388(ra) # 80000d26 <release>
}
    800027c2:	60e2                	ld	ra,24(sp)
    800027c4:	6442                	ld	s0,16(sp)
    800027c6:	64a2                	ld	s1,8(sp)
    800027c8:	6105                	addi	sp,sp,32
    800027ca:	8082                	ret

00000000800027cc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027cc:	1101                	addi	sp,sp,-32
    800027ce:	ec06                	sd	ra,24(sp)
    800027d0:	e822                	sd	s0,16(sp)
    800027d2:	e426                	sd	s1,8(sp)
    800027d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027da:	00074d63          	bltz	a4,800027f4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027de:	57fd                	li	a5,-1
    800027e0:	17fe                	slli	a5,a5,0x3f
    800027e2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027e6:	06f70363          	beq	a4,a5,8000284c <devintr+0x80>
  }
}
    800027ea:	60e2                	ld	ra,24(sp)
    800027ec:	6442                	ld	s0,16(sp)
    800027ee:	64a2                	ld	s1,8(sp)
    800027f0:	6105                	addi	sp,sp,32
    800027f2:	8082                	ret
     (scause & 0xff) == 9){
    800027f4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027f8:	46a5                	li	a3,9
    800027fa:	fed792e3          	bne	a5,a3,800027de <devintr+0x12>
    int irq = plic_claim();
    800027fe:	00003097          	auipc	ra,0x3
    80002802:	5da080e7          	jalr	1498(ra) # 80005dd8 <plic_claim>
    80002806:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002808:	47a9                	li	a5,10
    8000280a:	02f50763          	beq	a0,a5,80002838 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000280e:	4785                	li	a5,1
    80002810:	02f50963          	beq	a0,a5,80002842 <devintr+0x76>
    return 1;
    80002814:	4505                	li	a0,1
    } else if(irq){
    80002816:	d8f1                	beqz	s1,800027ea <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002818:	85a6                	mv	a1,s1
    8000281a:	00006517          	auipc	a0,0x6
    8000281e:	ad650513          	addi	a0,a0,-1322 # 800082f0 <states.0+0x30>
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	e10080e7          	jalr	-496(ra) # 80000632 <printf>
      plic_complete(irq);
    8000282a:	8526                	mv	a0,s1
    8000282c:	00003097          	auipc	ra,0x3
    80002830:	5d0080e7          	jalr	1488(ra) # 80005dfc <plic_complete>
    return 1;
    80002834:	4505                	li	a0,1
    80002836:	bf55                	j	800027ea <devintr+0x1e>
      uartintr();
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	1fe080e7          	jalr	510(ra) # 80000a36 <uartintr>
    80002840:	b7ed                	j	8000282a <devintr+0x5e>
      virtio_disk_intr();
    80002842:	00004097          	auipc	ra,0x4
    80002846:	a34080e7          	jalr	-1484(ra) # 80006276 <virtio_disk_intr>
    8000284a:	b7c5                	j	8000282a <devintr+0x5e>
    if(cpuid() == 0){
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	1c6080e7          	jalr	454(ra) # 80001a12 <cpuid>
    80002854:	c901                	beqz	a0,80002864 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002856:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000285a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000285c:	14479073          	csrw	sip,a5
    return 2;
    80002860:	4509                	li	a0,2
    80002862:	b761                	j	800027ea <devintr+0x1e>
      clockintr();
    80002864:	00000097          	auipc	ra,0x0
    80002868:	f22080e7          	jalr	-222(ra) # 80002786 <clockintr>
    8000286c:	b7ed                	j	80002856 <devintr+0x8a>

000000008000286e <usertrap>:
{
    8000286e:	1101                	addi	sp,sp,-32
    80002870:	ec06                	sd	ra,24(sp)
    80002872:	e822                	sd	s0,16(sp)
    80002874:	e426                	sd	s1,8(sp)
    80002876:	e04a                	sd	s2,0(sp)
    80002878:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000287e:	1007f793          	andi	a5,a5,256
    80002882:	e3ad                	bnez	a5,800028e4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002884:	00003797          	auipc	a5,0x3
    80002888:	44c78793          	addi	a5,a5,1100 # 80005cd0 <kernelvec>
    8000288c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002890:	fffff097          	auipc	ra,0xfffff
    80002894:	1ae080e7          	jalr	430(ra) # 80001a3e <myproc>
    80002898:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000289a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000289c:	14102773          	csrr	a4,sepc
    800028a0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028a6:	47a1                	li	a5,8
    800028a8:	04f71c63          	bne	a4,a5,80002900 <usertrap+0x92>
    if(p->killed)
    800028ac:	591c                	lw	a5,48(a0)
    800028ae:	e3b9                	bnez	a5,800028f4 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028b0:	6cb8                	ld	a4,88(s1)
    800028b2:	6f1c                	ld	a5,24(a4)
    800028b4:	0791                	addi	a5,a5,4
    800028b6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028bc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c0:	10079073          	csrw	sstatus,a5
    syscall();
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	3b6080e7          	jalr	950(ra) # 80002c7a <syscall>
  if(p->killed)
    800028cc:	589c                	lw	a5,48(s1)
    800028ce:	e7c5                	bnez	a5,80002976 <usertrap+0x108>
  usertrapret();
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	e18080e7          	jalr	-488(ra) # 800026e8 <usertrapret>
}
    800028d8:	60e2                	ld	ra,24(sp)
    800028da:	6442                	ld	s0,16(sp)
    800028dc:	64a2                	ld	s1,8(sp)
    800028de:	6902                	ld	s2,0(sp)
    800028e0:	6105                	addi	sp,sp,32
    800028e2:	8082                	ret
    panic("usertrap: not from user mode");
    800028e4:	00006517          	auipc	a0,0x6
    800028e8:	a2c50513          	addi	a0,a0,-1492 # 80008310 <states.0+0x50>
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	cf4080e7          	jalr	-780(ra) # 800005e0 <panic>
      exit(-1);
    800028f4:	557d                	li	a0,-1
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	84e080e7          	jalr	-1970(ra) # 80002144 <exit>
    800028fe:	bf4d                	j	800028b0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002900:	00000097          	auipc	ra,0x0
    80002904:	ecc080e7          	jalr	-308(ra) # 800027cc <devintr>
    80002908:	892a                	mv	s2,a0
    8000290a:	c501                	beqz	a0,80002912 <usertrap+0xa4>
  if(p->killed)
    8000290c:	589c                	lw	a5,48(s1)
    8000290e:	c3a1                	beqz	a5,8000294e <usertrap+0xe0>
    80002910:	a815                	j	80002944 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002912:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002916:	5c90                	lw	a2,56(s1)
    80002918:	00006517          	auipc	a0,0x6
    8000291c:	a1850513          	addi	a0,a0,-1512 # 80008330 <states.0+0x70>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	d12080e7          	jalr	-750(ra) # 80000632 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002928:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000292c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002930:	00006517          	auipc	a0,0x6
    80002934:	a3050513          	addi	a0,a0,-1488 # 80008360 <states.0+0xa0>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	cfa080e7          	jalr	-774(ra) # 80000632 <printf>
    p->killed = 1;
    80002940:	4785                	li	a5,1
    80002942:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002944:	557d                	li	a0,-1
    80002946:	fffff097          	auipc	ra,0xfffff
    8000294a:	7fe080e7          	jalr	2046(ra) # 80002144 <exit>
  if(which_dev == 2)
    8000294e:	4789                	li	a5,2
    80002950:	f8f910e3          	bne	s2,a5,800028d0 <usertrap+0x62>
    if(p->ticks!=0)//&&p->ticknum==p->ticks&&p->alarm_lock==0)
    80002954:	1784a783          	lw	a5,376(s1)
    80002958:	cb91                	beqz	a5,8000296c <usertrap+0xfe>
      p->ticknum++;
    8000295a:	17c4a703          	lw	a4,380(s1)
    8000295e:	2705                	addiw	a4,a4,1
    80002960:	0007069b          	sext.w	a3,a4
    80002964:	16e4ae23          	sw	a4,380(s1)
      if(p->ticknum==p->ticks&&p->alarm_lock==0)
    80002968:	00d78963          	beq	a5,a3,8000297a <usertrap+0x10c>
    yield();
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	8e2080e7          	jalr	-1822(ra) # 8000224e <yield>
    80002974:	bfb1                	j	800028d0 <usertrap+0x62>
  int which_dev = 0;
    80002976:	4901                	li	s2,0
    80002978:	b7f1                	j	80002944 <usertrap+0xd6>
      if(p->ticknum==p->ticks&&p->alarm_lock==0)
    8000297a:	54bc                	lw	a5,104(s1)
    8000297c:	fbe5                	bnez	a5,8000296c <usertrap+0xfe>
      p->alarm_lock=1;
    8000297e:	4785                	li	a5,1
    80002980:	d4bc                	sw	a5,104(s1)
      *(p->alarm_trapframe)=*(p->trapframe);
    80002982:	6cb4                	ld	a3,88(s1)
    80002984:	87b6                	mv	a5,a3
    80002986:	70b8                	ld	a4,96(s1)
    80002988:	12068693          	addi	a3,a3,288
    8000298c:	0007b803          	ld	a6,0(a5)
    80002990:	6788                	ld	a0,8(a5)
    80002992:	6b8c                	ld	a1,16(a5)
    80002994:	6f90                	ld	a2,24(a5)
    80002996:	01073023          	sd	a6,0(a4)
    8000299a:	e708                	sd	a0,8(a4)
    8000299c:	eb0c                	sd	a1,16(a4)
    8000299e:	ef10                	sd	a2,24(a4)
    800029a0:	02078793          	addi	a5,a5,32
    800029a4:	02070713          	addi	a4,a4,32
    800029a8:	fed792e3          	bne	a5,a3,8000298c <usertrap+0x11e>
      p->trapframe->epc=(uint64)(p->handler);
    800029ac:	6cbc                	ld	a5,88(s1)
    800029ae:	1804b703          	ld	a4,384(s1)
    800029b2:	ef98                	sd	a4,24(a5)
    800029b4:	bf65                	j	8000296c <usertrap+0xfe>

00000000800029b6 <kerneltrap>:
{
    800029b6:	7179                	addi	sp,sp,-48
    800029b8:	f406                	sd	ra,40(sp)
    800029ba:	f022                	sd	s0,32(sp)
    800029bc:	ec26                	sd	s1,24(sp)
    800029be:	e84a                	sd	s2,16(sp)
    800029c0:	e44e                	sd	s3,8(sp)
    800029c2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029cc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029d0:	1004f793          	andi	a5,s1,256
    800029d4:	cb85                	beqz	a5,80002a04 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029da:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029dc:	ef85                	bnez	a5,80002a14 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	dee080e7          	jalr	-530(ra) # 800027cc <devintr>
    800029e6:	cd1d                	beqz	a0,80002a24 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e8:	4789                	li	a5,2
    800029ea:	06f50a63          	beq	a0,a5,80002a5e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ee:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f2:	10049073          	csrw	sstatus,s1
}
    800029f6:	70a2                	ld	ra,40(sp)
    800029f8:	7402                	ld	s0,32(sp)
    800029fa:	64e2                	ld	s1,24(sp)
    800029fc:	6942                	ld	s2,16(sp)
    800029fe:	69a2                	ld	s3,8(sp)
    80002a00:	6145                	addi	sp,sp,48
    80002a02:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	97c50513          	addi	a0,a0,-1668 # 80008380 <states.0+0xc0>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	bd4080e7          	jalr	-1068(ra) # 800005e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	99450513          	addi	a0,a0,-1644 # 800083a8 <states.0+0xe8>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	bc4080e7          	jalr	-1084(ra) # 800005e0 <panic>
    printf("scause %p\n", scause);
    80002a24:	85ce                	mv	a1,s3
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	9a250513          	addi	a0,a0,-1630 # 800083c8 <states.0+0x108>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	c04080e7          	jalr	-1020(ra) # 80000632 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a36:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a3a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	99a50513          	addi	a0,a0,-1638 # 800083d8 <states.0+0x118>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	bec080e7          	jalr	-1044(ra) # 80000632 <printf>
    panic("kerneltrap");
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	9a250513          	addi	a0,a0,-1630 # 800083f0 <states.0+0x130>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	b8a080e7          	jalr	-1142(ra) # 800005e0 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	fe0080e7          	jalr	-32(ra) # 80001a3e <myproc>
    80002a66:	d541                	beqz	a0,800029ee <kerneltrap+0x38>
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	fd6080e7          	jalr	-42(ra) # 80001a3e <myproc>
    80002a70:	4d18                	lw	a4,24(a0)
    80002a72:	478d                	li	a5,3
    80002a74:	f6f71de3          	bne	a4,a5,800029ee <kerneltrap+0x38>
    yield();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	7d6080e7          	jalr	2006(ra) # 8000224e <yield>
    80002a80:	b7bd                	j	800029ee <kerneltrap+0x38>

0000000080002a82 <sigalarm>:

int sigalarm(int ticks, void (*handler)())
{
    80002a82:	1101                	addi	sp,sp,-32
    80002a84:	ec06                	sd	ra,24(sp)
    80002a86:	e822                	sd	s0,16(sp)
    80002a88:	e426                	sd	s1,8(sp)
    80002a8a:	e04a                	sd	s2,0(sp)
    80002a8c:	1000                	addi	s0,sp,32
    80002a8e:	892a                	mv	s2,a0
    80002a90:	84ae                	mv	s1,a1
  struct proc *p=myproc();
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	fac080e7          	jalr	-84(ra) # 80001a3e <myproc>
  p->ticks=ticks;
    80002a9a:	17252c23          	sw	s2,376(a0)
  p->handler=handler;
    80002a9e:	18953023          	sd	s1,384(a0)
  p->ticknum=0;
    80002aa2:	16052e23          	sw	zero,380(a0)
  //p->alarm_lock=1;
  return 0; 
}
    80002aa6:	4501                	li	a0,0
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6902                	ld	s2,0(sp)
    80002ab0:	6105                	addi	sp,sp,32
    80002ab2:	8082                	ret

0000000080002ab4 <sigreturn>:

int sigreturn(void)
{
    80002ab4:	1141                	addi	sp,sp,-16
    80002ab6:	e406                	sd	ra,8(sp)
    80002ab8:	e022                	sd	s0,0(sp)
    80002aba:	0800                	addi	s0,sp,16
   struct proc *p=myproc();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	f82080e7          	jalr	-126(ra) # 80001a3e <myproc>
   *(p->trapframe)=*(p->alarm_trapframe);
    80002ac4:	7134                	ld	a3,96(a0)
    80002ac6:	87b6                	mv	a5,a3
    80002ac8:	6d38                	ld	a4,88(a0)
    80002aca:	12068693          	addi	a3,a3,288
    80002ace:	0007b883          	ld	a7,0(a5)
    80002ad2:	0087b803          	ld	a6,8(a5)
    80002ad6:	6b8c                	ld	a1,16(a5)
    80002ad8:	6f90                	ld	a2,24(a5)
    80002ada:	01173023          	sd	a7,0(a4)
    80002ade:	01073423          	sd	a6,8(a4)
    80002ae2:	eb0c                	sd	a1,16(a4)
    80002ae4:	ef10                	sd	a2,24(a4)
    80002ae6:	02078793          	addi	a5,a5,32
    80002aea:	02070713          	addi	a4,a4,32
    80002aee:	fed790e3          	bne	a5,a3,80002ace <sigreturn+0x1a>
   p->alarm_lock=0;
    80002af2:	06052423          	sw	zero,104(a0)
   p->ticknum=0;
    80002af6:	16052e23          	sw	zero,380(a0)
   //printf("ret_from_alarm\n");
   return 0;
}
    80002afa:	4501                	li	a0,0
    80002afc:	60a2                	ld	ra,8(sp)
    80002afe:	6402                	ld	s0,0(sp)
    80002b00:	0141                	addi	sp,sp,16
    80002b02:	8082                	ret

0000000080002b04 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b04:	1101                	addi	sp,sp,-32
    80002b06:	ec06                	sd	ra,24(sp)
    80002b08:	e822                	sd	s0,16(sp)
    80002b0a:	e426                	sd	s1,8(sp)
    80002b0c:	1000                	addi	s0,sp,32
    80002b0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	f2e080e7          	jalr	-210(ra) # 80001a3e <myproc>
  switch (n) {
    80002b18:	4795                	li	a5,5
    80002b1a:	0497e163          	bltu	a5,s1,80002b5c <argraw+0x58>
    80002b1e:	048a                	slli	s1,s1,0x2
    80002b20:	00006717          	auipc	a4,0x6
    80002b24:	90870713          	addi	a4,a4,-1784 # 80008428 <states.0+0x168>
    80002b28:	94ba                	add	s1,s1,a4
    80002b2a:	409c                	lw	a5,0(s1)
    80002b2c:	97ba                	add	a5,a5,a4
    80002b2e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b30:	6d3c                	ld	a5,88(a0)
    80002b32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret
    return p->trapframe->a1;
    80002b3e:	6d3c                	ld	a5,88(a0)
    80002b40:	7fa8                	ld	a0,120(a5)
    80002b42:	bfcd                	j	80002b34 <argraw+0x30>
    return p->trapframe->a2;
    80002b44:	6d3c                	ld	a5,88(a0)
    80002b46:	63c8                	ld	a0,128(a5)
    80002b48:	b7f5                	j	80002b34 <argraw+0x30>
    return p->trapframe->a3;
    80002b4a:	6d3c                	ld	a5,88(a0)
    80002b4c:	67c8                	ld	a0,136(a5)
    80002b4e:	b7dd                	j	80002b34 <argraw+0x30>
    return p->trapframe->a4;
    80002b50:	6d3c                	ld	a5,88(a0)
    80002b52:	6bc8                	ld	a0,144(a5)
    80002b54:	b7c5                	j	80002b34 <argraw+0x30>
    return p->trapframe->a5;
    80002b56:	6d3c                	ld	a5,88(a0)
    80002b58:	6fc8                	ld	a0,152(a5)
    80002b5a:	bfe9                	j	80002b34 <argraw+0x30>
  panic("argraw");
    80002b5c:	00006517          	auipc	a0,0x6
    80002b60:	8a450513          	addi	a0,a0,-1884 # 80008400 <states.0+0x140>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a7c080e7          	jalr	-1412(ra) # 800005e0 <panic>

0000000080002b6c <fetchaddr>:
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	e04a                	sd	s2,0(sp)
    80002b76:	1000                	addi	s0,sp,32
    80002b78:	84aa                	mv	s1,a0
    80002b7a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	ec2080e7          	jalr	-318(ra) # 80001a3e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b84:	653c                	ld	a5,72(a0)
    80002b86:	02f4f863          	bgeu	s1,a5,80002bb6 <fetchaddr+0x4a>
    80002b8a:	00848713          	addi	a4,s1,8
    80002b8e:	02e7e663          	bltu	a5,a4,80002bba <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b92:	46a1                	li	a3,8
    80002b94:	8626                	mv	a2,s1
    80002b96:	85ca                	mv	a1,s2
    80002b98:	6928                	ld	a0,80(a0)
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	c22080e7          	jalr	-990(ra) # 800017bc <copyin>
    80002ba2:	00a03533          	snez	a0,a0
    80002ba6:	40a00533          	neg	a0,a0
}
    80002baa:	60e2                	ld	ra,24(sp)
    80002bac:	6442                	ld	s0,16(sp)
    80002bae:	64a2                	ld	s1,8(sp)
    80002bb0:	6902                	ld	s2,0(sp)
    80002bb2:	6105                	addi	sp,sp,32
    80002bb4:	8082                	ret
    return -1;
    80002bb6:	557d                	li	a0,-1
    80002bb8:	bfcd                	j	80002baa <fetchaddr+0x3e>
    80002bba:	557d                	li	a0,-1
    80002bbc:	b7fd                	j	80002baa <fetchaddr+0x3e>

0000000080002bbe <fetchstr>:
{
    80002bbe:	7179                	addi	sp,sp,-48
    80002bc0:	f406                	sd	ra,40(sp)
    80002bc2:	f022                	sd	s0,32(sp)
    80002bc4:	ec26                	sd	s1,24(sp)
    80002bc6:	e84a                	sd	s2,16(sp)
    80002bc8:	e44e                	sd	s3,8(sp)
    80002bca:	1800                	addi	s0,sp,48
    80002bcc:	892a                	mv	s2,a0
    80002bce:	84ae                	mv	s1,a1
    80002bd0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	e6c080e7          	jalr	-404(ra) # 80001a3e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bda:	86ce                	mv	a3,s3
    80002bdc:	864a                	mv	a2,s2
    80002bde:	85a6                	mv	a1,s1
    80002be0:	6928                	ld	a0,80(a0)
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	c68080e7          	jalr	-920(ra) # 8000184a <copyinstr>
  if(err < 0)
    80002bea:	00054763          	bltz	a0,80002bf8 <fetchstr+0x3a>
  return strlen(buf);
    80002bee:	8526                	mv	a0,s1
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	302080e7          	jalr	770(ra) # 80000ef2 <strlen>
}
    80002bf8:	70a2                	ld	ra,40(sp)
    80002bfa:	7402                	ld	s0,32(sp)
    80002bfc:	64e2                	ld	s1,24(sp)
    80002bfe:	6942                	ld	s2,16(sp)
    80002c00:	69a2                	ld	s3,8(sp)
    80002c02:	6145                	addi	sp,sp,48
    80002c04:	8082                	ret

0000000080002c06 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c06:	1101                	addi	sp,sp,-32
    80002c08:	ec06                	sd	ra,24(sp)
    80002c0a:	e822                	sd	s0,16(sp)
    80002c0c:	e426                	sd	s1,8(sp)
    80002c0e:	1000                	addi	s0,sp,32
    80002c10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	ef2080e7          	jalr	-270(ra) # 80002b04 <argraw>
    80002c1a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c1c:	4501                	li	a0,0
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret

0000000080002c28 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	1000                	addi	s0,sp,32
    80002c32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	ed0080e7          	jalr	-304(ra) # 80002b04 <argraw>
    80002c3c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c3e:	4501                	li	a0,0
    80002c40:	60e2                	ld	ra,24(sp)
    80002c42:	6442                	ld	s0,16(sp)
    80002c44:	64a2                	ld	s1,8(sp)
    80002c46:	6105                	addi	sp,sp,32
    80002c48:	8082                	ret

0000000080002c4a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c4a:	1101                	addi	sp,sp,-32
    80002c4c:	ec06                	sd	ra,24(sp)
    80002c4e:	e822                	sd	s0,16(sp)
    80002c50:	e426                	sd	s1,8(sp)
    80002c52:	e04a                	sd	s2,0(sp)
    80002c54:	1000                	addi	s0,sp,32
    80002c56:	84ae                	mv	s1,a1
    80002c58:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c5a:	00000097          	auipc	ra,0x0
    80002c5e:	eaa080e7          	jalr	-342(ra) # 80002b04 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c62:	864a                	mv	a2,s2
    80002c64:	85a6                	mv	a1,s1
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	f58080e7          	jalr	-168(ra) # 80002bbe <fetchstr>
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6902                	ld	s2,0(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret

0000000080002c7a <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002c7a:	1101                	addi	sp,sp,-32
    80002c7c:	ec06                	sd	ra,24(sp)
    80002c7e:	e822                	sd	s0,16(sp)
    80002c80:	e426                	sd	s1,8(sp)
    80002c82:	e04a                	sd	s2,0(sp)
    80002c84:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	db8080e7          	jalr	-584(ra) # 80001a3e <myproc>
    80002c8e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c90:	05853903          	ld	s2,88(a0)
    80002c94:	0a893783          	ld	a5,168(s2)
    80002c98:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c9c:	37fd                	addiw	a5,a5,-1
    80002c9e:	4759                	li	a4,22
    80002ca0:	00f76f63          	bltu	a4,a5,80002cbe <syscall+0x44>
    80002ca4:	00369713          	slli	a4,a3,0x3
    80002ca8:	00005797          	auipc	a5,0x5
    80002cac:	79878793          	addi	a5,a5,1944 # 80008440 <syscalls>
    80002cb0:	97ba                	add	a5,a5,a4
    80002cb2:	639c                	ld	a5,0(a5)
    80002cb4:	c789                	beqz	a5,80002cbe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cb6:	9782                	jalr	a5
    80002cb8:	06a93823          	sd	a0,112(s2)
    80002cbc:	a839                	j	80002cda <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cbe:	16848613          	addi	a2,s1,360
    80002cc2:	5c8c                	lw	a1,56(s1)
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	74450513          	addi	a0,a0,1860 # 80008408 <states.0+0x148>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	966080e7          	jalr	-1690(ra) # 80000632 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cd4:	6cbc                	ld	a5,88(s1)
    80002cd6:	577d                	li	a4,-1
    80002cd8:	fbb8                	sd	a4,112(a5)
  }
}
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	64a2                	ld	s1,8(sp)
    80002ce0:	6902                	ld	s2,0(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret

0000000080002ce6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ce6:	1101                	addi	sp,sp,-32
    80002ce8:	ec06                	sd	ra,24(sp)
    80002cea:	e822                	sd	s0,16(sp)
    80002cec:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cee:	fec40593          	addi	a1,s0,-20
    80002cf2:	4501                	li	a0,0
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	f12080e7          	jalr	-238(ra) # 80002c06 <argint>
    return -1;
    80002cfc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cfe:	00054963          	bltz	a0,80002d10 <sys_exit+0x2a>
  exit(n);
    80002d02:	fec42503          	lw	a0,-20(s0)
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	43e080e7          	jalr	1086(ra) # 80002144 <exit>
  return 0;  // not reached
    80002d0e:	4781                	li	a5,0
}
    80002d10:	853e                	mv	a0,a5
    80002d12:	60e2                	ld	ra,24(sp)
    80002d14:	6442                	ld	s0,16(sp)
    80002d16:	6105                	addi	sp,sp,32
    80002d18:	8082                	ret

0000000080002d1a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d1a:	1141                	addi	sp,sp,-16
    80002d1c:	e406                	sd	ra,8(sp)
    80002d1e:	e022                	sd	s0,0(sp)
    80002d20:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	d1c080e7          	jalr	-740(ra) # 80001a3e <myproc>
}
    80002d2a:	5d08                	lw	a0,56(a0)
    80002d2c:	60a2                	ld	ra,8(sp)
    80002d2e:	6402                	ld	s0,0(sp)
    80002d30:	0141                	addi	sp,sp,16
    80002d32:	8082                	ret

0000000080002d34 <sys_fork>:

uint64
sys_fork(void)
{
    80002d34:	1141                	addi	sp,sp,-16
    80002d36:	e406                	sd	ra,8(sp)
    80002d38:	e022                	sd	s0,0(sp)
    80002d3a:	0800                	addi	s0,sp,16
  return fork();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	0fe080e7          	jalr	254(ra) # 80001e3a <fork>
}
    80002d44:	60a2                	ld	ra,8(sp)
    80002d46:	6402                	ld	s0,0(sp)
    80002d48:	0141                	addi	sp,sp,16
    80002d4a:	8082                	ret

0000000080002d4c <sys_wait>:

uint64
sys_wait(void)
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d54:	fe840593          	addi	a1,s0,-24
    80002d58:	4501                	li	a0,0
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	ece080e7          	jalr	-306(ra) # 80002c28 <argaddr>
    80002d62:	87aa                	mv	a5,a0
    return -1;
    80002d64:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d66:	0007c863          	bltz	a5,80002d76 <sys_wait+0x2a>
  return wait(p);
    80002d6a:	fe843503          	ld	a0,-24(s0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	59a080e7          	jalr	1434(ra) # 80002308 <wait>
}
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d7e:	7179                	addi	sp,sp,-48
    80002d80:	f406                	sd	ra,40(sp)
    80002d82:	f022                	sd	s0,32(sp)
    80002d84:	ec26                	sd	s1,24(sp)
    80002d86:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d88:	fdc40593          	addi	a1,s0,-36
    80002d8c:	4501                	li	a0,0
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	e78080e7          	jalr	-392(ra) # 80002c06 <argint>
    return -1;
    80002d96:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d98:	00054f63          	bltz	a0,80002db6 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	ca2080e7          	jalr	-862(ra) # 80001a3e <myproc>
    80002da4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002da6:	fdc42503          	lw	a0,-36(s0)
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	01c080e7          	jalr	28(ra) # 80001dc6 <growproc>
    80002db2:	00054863          	bltz	a0,80002dc2 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002db6:	8526                	mv	a0,s1
    80002db8:	70a2                	ld	ra,40(sp)
    80002dba:	7402                	ld	s0,32(sp)
    80002dbc:	64e2                	ld	s1,24(sp)
    80002dbe:	6145                	addi	sp,sp,48
    80002dc0:	8082                	ret
    return -1;
    80002dc2:	54fd                	li	s1,-1
    80002dc4:	bfcd                	j	80002db6 <sys_sbrk+0x38>

0000000080002dc6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dc6:	7139                	addi	sp,sp,-64
    80002dc8:	fc06                	sd	ra,56(sp)
    80002dca:	f822                	sd	s0,48(sp)
    80002dcc:	f426                	sd	s1,40(sp)
    80002dce:	f04a                	sd	s2,32(sp)
    80002dd0:	ec4e                	sd	s3,24(sp)
    80002dd2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  backtrace();
    80002dd4:	ffffd097          	auipc	ra,0xffffd
    80002dd8:	7a0080e7          	jalr	1952(ra) # 80000574 <backtrace>
  if(argint(0, &n) < 0)
    80002ddc:	fcc40593          	addi	a1,s0,-52
    80002de0:	4501                	li	a0,0
    80002de2:	00000097          	auipc	ra,0x0
    80002de6:	e24080e7          	jalr	-476(ra) # 80002c06 <argint>
    return -1;
    80002dea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dec:	06054563          	bltz	a0,80002e56 <sys_sleep+0x90>
  acquire(&tickslock);
    80002df0:	00015517          	auipc	a0,0x15
    80002df4:	17850513          	addi	a0,a0,376 # 80017f68 <tickslock>
    80002df8:	ffffe097          	auipc	ra,0xffffe
    80002dfc:	e7a080e7          	jalr	-390(ra) # 80000c72 <acquire>
  ticks0 = ticks;
    80002e00:	00006917          	auipc	s2,0x6
    80002e04:	22092903          	lw	s2,544(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e08:	fcc42783          	lw	a5,-52(s0)
    80002e0c:	cf85                	beqz	a5,80002e44 <sys_sleep+0x7e>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e0e:	00015997          	auipc	s3,0x15
    80002e12:	15a98993          	addi	s3,s3,346 # 80017f68 <tickslock>
    80002e16:	00006497          	auipc	s1,0x6
    80002e1a:	20a48493          	addi	s1,s1,522 # 80009020 <ticks>
    if(myproc()->killed){
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	c20080e7          	jalr	-992(ra) # 80001a3e <myproc>
    80002e26:	591c                	lw	a5,48(a0)
    80002e28:	ef9d                	bnez	a5,80002e66 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002e2a:	85ce                	mv	a1,s3
    80002e2c:	8526                	mv	a0,s1
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	45c080e7          	jalr	1116(ra) # 8000228a <sleep>
  while(ticks - ticks0 < n){
    80002e36:	409c                	lw	a5,0(s1)
    80002e38:	412787bb          	subw	a5,a5,s2
    80002e3c:	fcc42703          	lw	a4,-52(s0)
    80002e40:	fce7efe3          	bltu	a5,a4,80002e1e <sys_sleep+0x58>
  }
  release(&tickslock);
    80002e44:	00015517          	auipc	a0,0x15
    80002e48:	12450513          	addi	a0,a0,292 # 80017f68 <tickslock>
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	eda080e7          	jalr	-294(ra) # 80000d26 <release>
  return 0;
    80002e54:	4781                	li	a5,0
}
    80002e56:	853e                	mv	a0,a5
    80002e58:	70e2                	ld	ra,56(sp)
    80002e5a:	7442                	ld	s0,48(sp)
    80002e5c:	74a2                	ld	s1,40(sp)
    80002e5e:	7902                	ld	s2,32(sp)
    80002e60:	69e2                	ld	s3,24(sp)
    80002e62:	6121                	addi	sp,sp,64
    80002e64:	8082                	ret
      release(&tickslock);
    80002e66:	00015517          	auipc	a0,0x15
    80002e6a:	10250513          	addi	a0,a0,258 # 80017f68 <tickslock>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	eb8080e7          	jalr	-328(ra) # 80000d26 <release>
      return -1;
    80002e76:	57fd                	li	a5,-1
    80002e78:	bff9                	j	80002e56 <sys_sleep+0x90>

0000000080002e7a <sys_kill>:

uint64
sys_kill(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e82:	fec40593          	addi	a1,s0,-20
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	d7e080e7          	jalr	-642(ra) # 80002c06 <argint>
    80002e90:	87aa                	mv	a5,a0
    return -1;
    80002e92:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e94:	0007c863          	bltz	a5,80002ea4 <sys_kill+0x2a>
  return kill(pid);
    80002e98:	fec42503          	lw	a0,-20(s0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	5d8080e7          	jalr	1496(ra) # 80002474 <kill>
}
    80002ea4:	60e2                	ld	ra,24(sp)
    80002ea6:	6442                	ld	s0,16(sp)
    80002ea8:	6105                	addi	sp,sp,32
    80002eaa:	8082                	ret

0000000080002eac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eac:	1101                	addi	sp,sp,-32
    80002eae:	ec06                	sd	ra,24(sp)
    80002eb0:	e822                	sd	s0,16(sp)
    80002eb2:	e426                	sd	s1,8(sp)
    80002eb4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eb6:	00015517          	auipc	a0,0x15
    80002eba:	0b250513          	addi	a0,a0,178 # 80017f68 <tickslock>
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	db4080e7          	jalr	-588(ra) # 80000c72 <acquire>
  xticks = ticks;
    80002ec6:	00006497          	auipc	s1,0x6
    80002eca:	15a4a483          	lw	s1,346(s1) # 80009020 <ticks>
  release(&tickslock);
    80002ece:	00015517          	auipc	a0,0x15
    80002ed2:	09a50513          	addi	a0,a0,154 # 80017f68 <tickslock>
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	e50080e7          	jalr	-432(ra) # 80000d26 <release>
  return xticks;
}
    80002ede:	02049513          	slli	a0,s1,0x20
    80002ee2:	9101                	srli	a0,a0,0x20
    80002ee4:	60e2                	ld	ra,24(sp)
    80002ee6:	6442                	ld	s0,16(sp)
    80002ee8:	64a2                	ld	s1,8(sp)
    80002eea:	6105                	addi	sp,sp,32
    80002eec:	8082                	ret

0000000080002eee <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80002eee:	1101                	addi	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handler;
  if(argint(0,&ticks)<0)
    80002ef6:	fec40593          	addi	a1,s0,-20
    80002efa:	4501                	li	a0,0
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	d0a080e7          	jalr	-758(ra) # 80002c06 <argint>
    return -1;
    80002f04:	57fd                	li	a5,-1
  if(argint(0,&ticks)<0)
    80002f06:	02054563          	bltz	a0,80002f30 <sys_sigalarm+0x42>
  if(argaddr(1,&handler)<0)
    80002f0a:	fe040593          	addi	a1,s0,-32
    80002f0e:	4505                	li	a0,1
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	d18080e7          	jalr	-744(ra) # 80002c28 <argaddr>
    return -1;
    80002f18:	57fd                	li	a5,-1
  if(argaddr(1,&handler)<0)
    80002f1a:	00054b63          	bltz	a0,80002f30 <sys_sigalarm+0x42>
  return sigalarm(ticks,(void(*)())handler);
    80002f1e:	fe043583          	ld	a1,-32(s0)
    80002f22:	fec42503          	lw	a0,-20(s0)
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	b5c080e7          	jalr	-1188(ra) # 80002a82 <sigalarm>
    80002f2e:	87aa                	mv	a5,a0
}
    80002f30:	853e                	mv	a0,a5
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80002f3a:	1141                	addi	sp,sp,-16
    80002f3c:	e406                	sd	ra,8(sp)
    80002f3e:	e022                	sd	s0,0(sp)
    80002f40:	0800                	addi	s0,sp,16
  return sigreturn();
    80002f42:	00000097          	auipc	ra,0x0
    80002f46:	b72080e7          	jalr	-1166(ra) # 80002ab4 <sigreturn>
}
    80002f4a:	60a2                	ld	ra,8(sp)
    80002f4c:	6402                	ld	s0,0(sp)
    80002f4e:	0141                	addi	sp,sp,16
    80002f50:	8082                	ret

0000000080002f52 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	e84a                	sd	s2,16(sp)
    80002f5c:	e44e                	sd	s3,8(sp)
    80002f5e:	e052                	sd	s4,0(sp)
    80002f60:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f62:	00005597          	auipc	a1,0x5
    80002f66:	59e58593          	addi	a1,a1,1438 # 80008500 <syscalls+0xc0>
    80002f6a:	00015517          	auipc	a0,0x15
    80002f6e:	01650513          	addi	a0,a0,22 # 80017f80 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	c70080e7          	jalr	-912(ra) # 80000be2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f7a:	0001d797          	auipc	a5,0x1d
    80002f7e:	00678793          	addi	a5,a5,6 # 8001ff80 <bcache+0x8000>
    80002f82:	0001d717          	auipc	a4,0x1d
    80002f86:	26670713          	addi	a4,a4,614 # 800201e8 <bcache+0x8268>
    80002f8a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f8e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f92:	00015497          	auipc	s1,0x15
    80002f96:	00648493          	addi	s1,s1,6 # 80017f98 <bcache+0x18>
    b->next = bcache.head.next;
    80002f9a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f9c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f9e:	00005a17          	auipc	s4,0x5
    80002fa2:	56aa0a13          	addi	s4,s4,1386 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fa6:	2b893783          	ld	a5,696(s2)
    80002faa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fac:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fb0:	85d2                	mv	a1,s4
    80002fb2:	01048513          	addi	a0,s1,16
    80002fb6:	00001097          	auipc	ra,0x1
    80002fba:	4ac080e7          	jalr	1196(ra) # 80004462 <initsleeplock>
    bcache.head.next->prev = b;
    80002fbe:	2b893783          	ld	a5,696(s2)
    80002fc2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fc4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc8:	45848493          	addi	s1,s1,1112
    80002fcc:	fd349de3          	bne	s1,s3,80002fa6 <binit+0x54>
  }
}
    80002fd0:	70a2                	ld	ra,40(sp)
    80002fd2:	7402                	ld	s0,32(sp)
    80002fd4:	64e2                	ld	s1,24(sp)
    80002fd6:	6942                	ld	s2,16(sp)
    80002fd8:	69a2                	ld	s3,8(sp)
    80002fda:	6a02                	ld	s4,0(sp)
    80002fdc:	6145                	addi	sp,sp,48
    80002fde:	8082                	ret

0000000080002fe0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fe0:	7179                	addi	sp,sp,-48
    80002fe2:	f406                	sd	ra,40(sp)
    80002fe4:	f022                	sd	s0,32(sp)
    80002fe6:	ec26                	sd	s1,24(sp)
    80002fe8:	e84a                	sd	s2,16(sp)
    80002fea:	e44e                	sd	s3,8(sp)
    80002fec:	1800                	addi	s0,sp,48
    80002fee:	892a                	mv	s2,a0
    80002ff0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ff2:	00015517          	auipc	a0,0x15
    80002ff6:	f8e50513          	addi	a0,a0,-114 # 80017f80 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	c78080e7          	jalr	-904(ra) # 80000c72 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003002:	0001d497          	auipc	s1,0x1d
    80003006:	2364b483          	ld	s1,566(s1) # 80020238 <bcache+0x82b8>
    8000300a:	0001d797          	auipc	a5,0x1d
    8000300e:	1de78793          	addi	a5,a5,478 # 800201e8 <bcache+0x8268>
    80003012:	02f48f63          	beq	s1,a5,80003050 <bread+0x70>
    80003016:	873e                	mv	a4,a5
    80003018:	a021                	j	80003020 <bread+0x40>
    8000301a:	68a4                	ld	s1,80(s1)
    8000301c:	02e48a63          	beq	s1,a4,80003050 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003020:	449c                	lw	a5,8(s1)
    80003022:	ff279ce3          	bne	a5,s2,8000301a <bread+0x3a>
    80003026:	44dc                	lw	a5,12(s1)
    80003028:	ff3799e3          	bne	a5,s3,8000301a <bread+0x3a>
      b->refcnt++;
    8000302c:	40bc                	lw	a5,64(s1)
    8000302e:	2785                	addiw	a5,a5,1
    80003030:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003032:	00015517          	auipc	a0,0x15
    80003036:	f4e50513          	addi	a0,a0,-178 # 80017f80 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	cec080e7          	jalr	-788(ra) # 80000d26 <release>
      acquiresleep(&b->lock);
    80003042:	01048513          	addi	a0,s1,16
    80003046:	00001097          	auipc	ra,0x1
    8000304a:	456080e7          	jalr	1110(ra) # 8000449c <acquiresleep>
      return b;
    8000304e:	a8b9                	j	800030ac <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003050:	0001d497          	auipc	s1,0x1d
    80003054:	1e04b483          	ld	s1,480(s1) # 80020230 <bcache+0x82b0>
    80003058:	0001d797          	auipc	a5,0x1d
    8000305c:	19078793          	addi	a5,a5,400 # 800201e8 <bcache+0x8268>
    80003060:	00f48863          	beq	s1,a5,80003070 <bread+0x90>
    80003064:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003066:	40bc                	lw	a5,64(s1)
    80003068:	cf81                	beqz	a5,80003080 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000306a:	64a4                	ld	s1,72(s1)
    8000306c:	fee49de3          	bne	s1,a4,80003066 <bread+0x86>
  panic("bget: no buffers");
    80003070:	00005517          	auipc	a0,0x5
    80003074:	4a050513          	addi	a0,a0,1184 # 80008510 <syscalls+0xd0>
    80003078:	ffffd097          	auipc	ra,0xffffd
    8000307c:	568080e7          	jalr	1384(ra) # 800005e0 <panic>
      b->dev = dev;
    80003080:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003084:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003088:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000308c:	4785                	li	a5,1
    8000308e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003090:	00015517          	auipc	a0,0x15
    80003094:	ef050513          	addi	a0,a0,-272 # 80017f80 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c8e080e7          	jalr	-882(ra) # 80000d26 <release>
      acquiresleep(&b->lock);
    800030a0:	01048513          	addi	a0,s1,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	3f8080e7          	jalr	1016(ra) # 8000449c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030ac:	409c                	lw	a5,0(s1)
    800030ae:	cb89                	beqz	a5,800030c0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030b0:	8526                	mv	a0,s1
    800030b2:	70a2                	ld	ra,40(sp)
    800030b4:	7402                	ld	s0,32(sp)
    800030b6:	64e2                	ld	s1,24(sp)
    800030b8:	6942                	ld	s2,16(sp)
    800030ba:	69a2                	ld	s3,8(sp)
    800030bc:	6145                	addi	sp,sp,48
    800030be:	8082                	ret
    virtio_disk_rw(b, 0);
    800030c0:	4581                	li	a1,0
    800030c2:	8526                	mv	a0,s1
    800030c4:	00003097          	auipc	ra,0x3
    800030c8:	f28080e7          	jalr	-216(ra) # 80005fec <virtio_disk_rw>
    b->valid = 1;
    800030cc:	4785                	li	a5,1
    800030ce:	c09c                	sw	a5,0(s1)
  return b;
    800030d0:	b7c5                	j	800030b0 <bread+0xd0>

00000000800030d2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	1000                	addi	s0,sp,32
    800030dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030de:	0541                	addi	a0,a0,16
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	456080e7          	jalr	1110(ra) # 80004536 <holdingsleep>
    800030e8:	cd01                	beqz	a0,80003100 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030ea:	4585                	li	a1,1
    800030ec:	8526                	mv	a0,s1
    800030ee:	00003097          	auipc	ra,0x3
    800030f2:	efe080e7          	jalr	-258(ra) # 80005fec <virtio_disk_rw>
}
    800030f6:	60e2                	ld	ra,24(sp)
    800030f8:	6442                	ld	s0,16(sp)
    800030fa:	64a2                	ld	s1,8(sp)
    800030fc:	6105                	addi	sp,sp,32
    800030fe:	8082                	ret
    panic("bwrite");
    80003100:	00005517          	auipc	a0,0x5
    80003104:	42850513          	addi	a0,a0,1064 # 80008528 <syscalls+0xe8>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	4d8080e7          	jalr	1240(ra) # 800005e0 <panic>

0000000080003110 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	e04a                	sd	s2,0(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311e:	01050913          	addi	s2,a0,16
    80003122:	854a                	mv	a0,s2
    80003124:	00001097          	auipc	ra,0x1
    80003128:	412080e7          	jalr	1042(ra) # 80004536 <holdingsleep>
    8000312c:	c92d                	beqz	a0,8000319e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000312e:	854a                	mv	a0,s2
    80003130:	00001097          	auipc	ra,0x1
    80003134:	3c2080e7          	jalr	962(ra) # 800044f2 <releasesleep>

  acquire(&bcache.lock);
    80003138:	00015517          	auipc	a0,0x15
    8000313c:	e4850513          	addi	a0,a0,-440 # 80017f80 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b32080e7          	jalr	-1230(ra) # 80000c72 <acquire>
  b->refcnt--;
    80003148:	40bc                	lw	a5,64(s1)
    8000314a:	37fd                	addiw	a5,a5,-1
    8000314c:	0007871b          	sext.w	a4,a5
    80003150:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003152:	eb05                	bnez	a4,80003182 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003154:	68bc                	ld	a5,80(s1)
    80003156:	64b8                	ld	a4,72(s1)
    80003158:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000315a:	64bc                	ld	a5,72(s1)
    8000315c:	68b8                	ld	a4,80(s1)
    8000315e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003160:	0001d797          	auipc	a5,0x1d
    80003164:	e2078793          	addi	a5,a5,-480 # 8001ff80 <bcache+0x8000>
    80003168:	2b87b703          	ld	a4,696(a5)
    8000316c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000316e:	0001d717          	auipc	a4,0x1d
    80003172:	07a70713          	addi	a4,a4,122 # 800201e8 <bcache+0x8268>
    80003176:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003178:	2b87b703          	ld	a4,696(a5)
    8000317c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000317e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003182:	00015517          	auipc	a0,0x15
    80003186:	dfe50513          	addi	a0,a0,-514 # 80017f80 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	b9c080e7          	jalr	-1124(ra) # 80000d26 <release>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	64a2                	ld	s1,8(sp)
    80003198:	6902                	ld	s2,0(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret
    panic("brelse");
    8000319e:	00005517          	auipc	a0,0x5
    800031a2:	39250513          	addi	a0,a0,914 # 80008530 <syscalls+0xf0>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	43a080e7          	jalr	1082(ra) # 800005e0 <panic>

00000000800031ae <bpin>:

void
bpin(struct buf *b) {
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ba:	00015517          	auipc	a0,0x15
    800031be:	dc650513          	addi	a0,a0,-570 # 80017f80 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	ab0080e7          	jalr	-1360(ra) # 80000c72 <acquire>
  b->refcnt++;
    800031ca:	40bc                	lw	a5,64(s1)
    800031cc:	2785                	addiw	a5,a5,1
    800031ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d0:	00015517          	auipc	a0,0x15
    800031d4:	db050513          	addi	a0,a0,-592 # 80017f80 <bcache>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	b4e080e7          	jalr	-1202(ra) # 80000d26 <release>
}
    800031e0:	60e2                	ld	ra,24(sp)
    800031e2:	6442                	ld	s0,16(sp)
    800031e4:	64a2                	ld	s1,8(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret

00000000800031ea <bunpin>:

void
bunpin(struct buf *b) {
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f6:	00015517          	auipc	a0,0x15
    800031fa:	d8a50513          	addi	a0,a0,-630 # 80017f80 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	a74080e7          	jalr	-1420(ra) # 80000c72 <acquire>
  b->refcnt--;
    80003206:	40bc                	lw	a5,64(s1)
    80003208:	37fd                	addiw	a5,a5,-1
    8000320a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000320c:	00015517          	auipc	a0,0x15
    80003210:	d7450513          	addi	a0,a0,-652 # 80017f80 <bcache>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	b12080e7          	jalr	-1262(ra) # 80000d26 <release>
}
    8000321c:	60e2                	ld	ra,24(sp)
    8000321e:	6442                	ld	s0,16(sp)
    80003220:	64a2                	ld	s1,8(sp)
    80003222:	6105                	addi	sp,sp,32
    80003224:	8082                	ret

0000000080003226 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003226:	1101                	addi	sp,sp,-32
    80003228:	ec06                	sd	ra,24(sp)
    8000322a:	e822                	sd	s0,16(sp)
    8000322c:	e426                	sd	s1,8(sp)
    8000322e:	e04a                	sd	s2,0(sp)
    80003230:	1000                	addi	s0,sp,32
    80003232:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003234:	00d5d59b          	srliw	a1,a1,0xd
    80003238:	0001d797          	auipc	a5,0x1d
    8000323c:	4247a783          	lw	a5,1060(a5) # 8002065c <sb+0x1c>
    80003240:	9dbd                	addw	a1,a1,a5
    80003242:	00000097          	auipc	ra,0x0
    80003246:	d9e080e7          	jalr	-610(ra) # 80002fe0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000324a:	0074f713          	andi	a4,s1,7
    8000324e:	4785                	li	a5,1
    80003250:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003254:	14ce                	slli	s1,s1,0x33
    80003256:	90d9                	srli	s1,s1,0x36
    80003258:	00950733          	add	a4,a0,s1
    8000325c:	05874703          	lbu	a4,88(a4)
    80003260:	00e7f6b3          	and	a3,a5,a4
    80003264:	c69d                	beqz	a3,80003292 <bfree+0x6c>
    80003266:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003268:	94aa                	add	s1,s1,a0
    8000326a:	fff7c793          	not	a5,a5
    8000326e:	8ff9                	and	a5,a5,a4
    80003270:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003274:	00001097          	auipc	ra,0x1
    80003278:	100080e7          	jalr	256(ra) # 80004374 <log_write>
  brelse(bp);
    8000327c:	854a                	mv	a0,s2
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	e92080e7          	jalr	-366(ra) # 80003110 <brelse>
}
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	64a2                	ld	s1,8(sp)
    8000328c:	6902                	ld	s2,0(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret
    panic("freeing free block");
    80003292:	00005517          	auipc	a0,0x5
    80003296:	2a650513          	addi	a0,a0,678 # 80008538 <syscalls+0xf8>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	346080e7          	jalr	838(ra) # 800005e0 <panic>

00000000800032a2 <balloc>:
{
    800032a2:	711d                	addi	sp,sp,-96
    800032a4:	ec86                	sd	ra,88(sp)
    800032a6:	e8a2                	sd	s0,80(sp)
    800032a8:	e4a6                	sd	s1,72(sp)
    800032aa:	e0ca                	sd	s2,64(sp)
    800032ac:	fc4e                	sd	s3,56(sp)
    800032ae:	f852                	sd	s4,48(sp)
    800032b0:	f456                	sd	s5,40(sp)
    800032b2:	f05a                	sd	s6,32(sp)
    800032b4:	ec5e                	sd	s7,24(sp)
    800032b6:	e862                	sd	s8,16(sp)
    800032b8:	e466                	sd	s9,8(sp)
    800032ba:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032bc:	0001d797          	auipc	a5,0x1d
    800032c0:	3887a783          	lw	a5,904(a5) # 80020644 <sb+0x4>
    800032c4:	cbd1                	beqz	a5,80003358 <balloc+0xb6>
    800032c6:	8baa                	mv	s7,a0
    800032c8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032ca:	0001db17          	auipc	s6,0x1d
    800032ce:	376b0b13          	addi	s6,s6,886 # 80020640 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032d4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032d8:	6c89                	lui	s9,0x2
    800032da:	a831                	j	800032f6 <balloc+0x54>
    brelse(bp);
    800032dc:	854a                	mv	a0,s2
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	e32080e7          	jalr	-462(ra) # 80003110 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032e6:	015c87bb          	addw	a5,s9,s5
    800032ea:	00078a9b          	sext.w	s5,a5
    800032ee:	004b2703          	lw	a4,4(s6)
    800032f2:	06eaf363          	bgeu	s5,a4,80003358 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032f6:	41fad79b          	sraiw	a5,s5,0x1f
    800032fa:	0137d79b          	srliw	a5,a5,0x13
    800032fe:	015787bb          	addw	a5,a5,s5
    80003302:	40d7d79b          	sraiw	a5,a5,0xd
    80003306:	01cb2583          	lw	a1,28(s6)
    8000330a:	9dbd                	addw	a1,a1,a5
    8000330c:	855e                	mv	a0,s7
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	cd2080e7          	jalr	-814(ra) # 80002fe0 <bread>
    80003316:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003318:	004b2503          	lw	a0,4(s6)
    8000331c:	000a849b          	sext.w	s1,s5
    80003320:	8662                	mv	a2,s8
    80003322:	faa4fde3          	bgeu	s1,a0,800032dc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003326:	41f6579b          	sraiw	a5,a2,0x1f
    8000332a:	01d7d69b          	srliw	a3,a5,0x1d
    8000332e:	00c6873b          	addw	a4,a3,a2
    80003332:	00777793          	andi	a5,a4,7
    80003336:	9f95                	subw	a5,a5,a3
    80003338:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000333c:	4037571b          	sraiw	a4,a4,0x3
    80003340:	00e906b3          	add	a3,s2,a4
    80003344:	0586c683          	lbu	a3,88(a3)
    80003348:	00d7f5b3          	and	a1,a5,a3
    8000334c:	cd91                	beqz	a1,80003368 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334e:	2605                	addiw	a2,a2,1
    80003350:	2485                	addiw	s1,s1,1
    80003352:	fd4618e3          	bne	a2,s4,80003322 <balloc+0x80>
    80003356:	b759                	j	800032dc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003358:	00005517          	auipc	a0,0x5
    8000335c:	1f850513          	addi	a0,a0,504 # 80008550 <syscalls+0x110>
    80003360:	ffffd097          	auipc	ra,0xffffd
    80003364:	280080e7          	jalr	640(ra) # 800005e0 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003368:	974a                	add	a4,a4,s2
    8000336a:	8fd5                	or	a5,a5,a3
    8000336c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003370:	854a                	mv	a0,s2
    80003372:	00001097          	auipc	ra,0x1
    80003376:	002080e7          	jalr	2(ra) # 80004374 <log_write>
        brelse(bp);
    8000337a:	854a                	mv	a0,s2
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	d94080e7          	jalr	-620(ra) # 80003110 <brelse>
  bp = bread(dev, bno);
    80003384:	85a6                	mv	a1,s1
    80003386:	855e                	mv	a0,s7
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	c58080e7          	jalr	-936(ra) # 80002fe0 <bread>
    80003390:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003392:	40000613          	li	a2,1024
    80003396:	4581                	li	a1,0
    80003398:	05850513          	addi	a0,a0,88
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	9d2080e7          	jalr	-1582(ra) # 80000d6e <memset>
  log_write(bp);
    800033a4:	854a                	mv	a0,s2
    800033a6:	00001097          	auipc	ra,0x1
    800033aa:	fce080e7          	jalr	-50(ra) # 80004374 <log_write>
  brelse(bp);
    800033ae:	854a                	mv	a0,s2
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	d60080e7          	jalr	-672(ra) # 80003110 <brelse>
}
    800033b8:	8526                	mv	a0,s1
    800033ba:	60e6                	ld	ra,88(sp)
    800033bc:	6446                	ld	s0,80(sp)
    800033be:	64a6                	ld	s1,72(sp)
    800033c0:	6906                	ld	s2,64(sp)
    800033c2:	79e2                	ld	s3,56(sp)
    800033c4:	7a42                	ld	s4,48(sp)
    800033c6:	7aa2                	ld	s5,40(sp)
    800033c8:	7b02                	ld	s6,32(sp)
    800033ca:	6be2                	ld	s7,24(sp)
    800033cc:	6c42                	ld	s8,16(sp)
    800033ce:	6ca2                	ld	s9,8(sp)
    800033d0:	6125                	addi	sp,sp,96
    800033d2:	8082                	ret

00000000800033d4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033d4:	7179                	addi	sp,sp,-48
    800033d6:	f406                	sd	ra,40(sp)
    800033d8:	f022                	sd	s0,32(sp)
    800033da:	ec26                	sd	s1,24(sp)
    800033dc:	e84a                	sd	s2,16(sp)
    800033de:	e44e                	sd	s3,8(sp)
    800033e0:	e052                	sd	s4,0(sp)
    800033e2:	1800                	addi	s0,sp,48
    800033e4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033e6:	47ad                	li	a5,11
    800033e8:	04b7fe63          	bgeu	a5,a1,80003444 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033ec:	ff45849b          	addiw	s1,a1,-12
    800033f0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033f4:	0ff00793          	li	a5,255
    800033f8:	0ae7e363          	bltu	a5,a4,8000349e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033fc:	08052583          	lw	a1,128(a0)
    80003400:	c5ad                	beqz	a1,8000346a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003402:	00092503          	lw	a0,0(s2)
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	bda080e7          	jalr	-1062(ra) # 80002fe0 <bread>
    8000340e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003410:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003414:	02049593          	slli	a1,s1,0x20
    80003418:	9181                	srli	a1,a1,0x20
    8000341a:	058a                	slli	a1,a1,0x2
    8000341c:	00b784b3          	add	s1,a5,a1
    80003420:	0004a983          	lw	s3,0(s1)
    80003424:	04098d63          	beqz	s3,8000347e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003428:	8552                	mv	a0,s4
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	ce6080e7          	jalr	-794(ra) # 80003110 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003432:	854e                	mv	a0,s3
    80003434:	70a2                	ld	ra,40(sp)
    80003436:	7402                	ld	s0,32(sp)
    80003438:	64e2                	ld	s1,24(sp)
    8000343a:	6942                	ld	s2,16(sp)
    8000343c:	69a2                	ld	s3,8(sp)
    8000343e:	6a02                	ld	s4,0(sp)
    80003440:	6145                	addi	sp,sp,48
    80003442:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003444:	02059493          	slli	s1,a1,0x20
    80003448:	9081                	srli	s1,s1,0x20
    8000344a:	048a                	slli	s1,s1,0x2
    8000344c:	94aa                	add	s1,s1,a0
    8000344e:	0504a983          	lw	s3,80(s1)
    80003452:	fe0990e3          	bnez	s3,80003432 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003456:	4108                	lw	a0,0(a0)
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e4a080e7          	jalr	-438(ra) # 800032a2 <balloc>
    80003460:	0005099b          	sext.w	s3,a0
    80003464:	0534a823          	sw	s3,80(s1)
    80003468:	b7e9                	j	80003432 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000346a:	4108                	lw	a0,0(a0)
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	e36080e7          	jalr	-458(ra) # 800032a2 <balloc>
    80003474:	0005059b          	sext.w	a1,a0
    80003478:	08b92023          	sw	a1,128(s2)
    8000347c:	b759                	j	80003402 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000347e:	00092503          	lw	a0,0(s2)
    80003482:	00000097          	auipc	ra,0x0
    80003486:	e20080e7          	jalr	-480(ra) # 800032a2 <balloc>
    8000348a:	0005099b          	sext.w	s3,a0
    8000348e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003492:	8552                	mv	a0,s4
    80003494:	00001097          	auipc	ra,0x1
    80003498:	ee0080e7          	jalr	-288(ra) # 80004374 <log_write>
    8000349c:	b771                	j	80003428 <bmap+0x54>
  panic("bmap: out of range");
    8000349e:	00005517          	auipc	a0,0x5
    800034a2:	0ca50513          	addi	a0,a0,202 # 80008568 <syscalls+0x128>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	13a080e7          	jalr	314(ra) # 800005e0 <panic>

00000000800034ae <iget>:
{
    800034ae:	7179                	addi	sp,sp,-48
    800034b0:	f406                	sd	ra,40(sp)
    800034b2:	f022                	sd	s0,32(sp)
    800034b4:	ec26                	sd	s1,24(sp)
    800034b6:	e84a                	sd	s2,16(sp)
    800034b8:	e44e                	sd	s3,8(sp)
    800034ba:	e052                	sd	s4,0(sp)
    800034bc:	1800                	addi	s0,sp,48
    800034be:	89aa                	mv	s3,a0
    800034c0:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034c2:	0001d517          	auipc	a0,0x1d
    800034c6:	19e50513          	addi	a0,a0,414 # 80020660 <icache>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	7a8080e7          	jalr	1960(ra) # 80000c72 <acquire>
  empty = 0;
    800034d2:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034d4:	0001d497          	auipc	s1,0x1d
    800034d8:	1a448493          	addi	s1,s1,420 # 80020678 <icache+0x18>
    800034dc:	0001f697          	auipc	a3,0x1f
    800034e0:	c2c68693          	addi	a3,a3,-980 # 80022108 <log>
    800034e4:	a039                	j	800034f2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e6:	02090b63          	beqz	s2,8000351c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034ea:	08848493          	addi	s1,s1,136
    800034ee:	02d48a63          	beq	s1,a3,80003522 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034f2:	449c                	lw	a5,8(s1)
    800034f4:	fef059e3          	blez	a5,800034e6 <iget+0x38>
    800034f8:	4098                	lw	a4,0(s1)
    800034fa:	ff3716e3          	bne	a4,s3,800034e6 <iget+0x38>
    800034fe:	40d8                	lw	a4,4(s1)
    80003500:	ff4713e3          	bne	a4,s4,800034e6 <iget+0x38>
      ip->ref++;
    80003504:	2785                	addiw	a5,a5,1
    80003506:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003508:	0001d517          	auipc	a0,0x1d
    8000350c:	15850513          	addi	a0,a0,344 # 80020660 <icache>
    80003510:	ffffe097          	auipc	ra,0xffffe
    80003514:	816080e7          	jalr	-2026(ra) # 80000d26 <release>
      return ip;
    80003518:	8926                	mv	s2,s1
    8000351a:	a03d                	j	80003548 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000351c:	f7f9                	bnez	a5,800034ea <iget+0x3c>
    8000351e:	8926                	mv	s2,s1
    80003520:	b7e9                	j	800034ea <iget+0x3c>
  if(empty == 0)
    80003522:	02090c63          	beqz	s2,8000355a <iget+0xac>
  ip->dev = dev;
    80003526:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000352a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000352e:	4785                	li	a5,1
    80003530:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003534:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003538:	0001d517          	auipc	a0,0x1d
    8000353c:	12850513          	addi	a0,a0,296 # 80020660 <icache>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	7e6080e7          	jalr	2022(ra) # 80000d26 <release>
}
    80003548:	854a                	mv	a0,s2
    8000354a:	70a2                	ld	ra,40(sp)
    8000354c:	7402                	ld	s0,32(sp)
    8000354e:	64e2                	ld	s1,24(sp)
    80003550:	6942                	ld	s2,16(sp)
    80003552:	69a2                	ld	s3,8(sp)
    80003554:	6a02                	ld	s4,0(sp)
    80003556:	6145                	addi	sp,sp,48
    80003558:	8082                	ret
    panic("iget: no inodes");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	02650513          	addi	a0,a0,38 # 80008580 <syscalls+0x140>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	07e080e7          	jalr	126(ra) # 800005e0 <panic>

000000008000356a <fsinit>:
fsinit(int dev) {
    8000356a:	7179                	addi	sp,sp,-48
    8000356c:	f406                	sd	ra,40(sp)
    8000356e:	f022                	sd	s0,32(sp)
    80003570:	ec26                	sd	s1,24(sp)
    80003572:	e84a                	sd	s2,16(sp)
    80003574:	e44e                	sd	s3,8(sp)
    80003576:	1800                	addi	s0,sp,48
    80003578:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000357a:	4585                	li	a1,1
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	a64080e7          	jalr	-1436(ra) # 80002fe0 <bread>
    80003584:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003586:	0001d997          	auipc	s3,0x1d
    8000358a:	0ba98993          	addi	s3,s3,186 # 80020640 <sb>
    8000358e:	02000613          	li	a2,32
    80003592:	05850593          	addi	a1,a0,88
    80003596:	854e                	mv	a0,s3
    80003598:	ffffe097          	auipc	ra,0xffffe
    8000359c:	832080e7          	jalr	-1998(ra) # 80000dca <memmove>
  brelse(bp);
    800035a0:	8526                	mv	a0,s1
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	b6e080e7          	jalr	-1170(ra) # 80003110 <brelse>
  if(sb.magic != FSMAGIC)
    800035aa:	0009a703          	lw	a4,0(s3)
    800035ae:	102037b7          	lui	a5,0x10203
    800035b2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035b6:	02f71263          	bne	a4,a5,800035da <fsinit+0x70>
  initlog(dev, &sb);
    800035ba:	0001d597          	auipc	a1,0x1d
    800035be:	08658593          	addi	a1,a1,134 # 80020640 <sb>
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	b38080e7          	jalr	-1224(ra) # 800040fc <initlog>
}
    800035cc:	70a2                	ld	ra,40(sp)
    800035ce:	7402                	ld	s0,32(sp)
    800035d0:	64e2                	ld	s1,24(sp)
    800035d2:	6942                	ld	s2,16(sp)
    800035d4:	69a2                	ld	s3,8(sp)
    800035d6:	6145                	addi	sp,sp,48
    800035d8:	8082                	ret
    panic("invalid file system");
    800035da:	00005517          	auipc	a0,0x5
    800035de:	fb650513          	addi	a0,a0,-74 # 80008590 <syscalls+0x150>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	ffe080e7          	jalr	-2(ra) # 800005e0 <panic>

00000000800035ea <iinit>:
{
    800035ea:	7179                	addi	sp,sp,-48
    800035ec:	f406                	sd	ra,40(sp)
    800035ee:	f022                	sd	s0,32(sp)
    800035f0:	ec26                	sd	s1,24(sp)
    800035f2:	e84a                	sd	s2,16(sp)
    800035f4:	e44e                	sd	s3,8(sp)
    800035f6:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035f8:	00005597          	auipc	a1,0x5
    800035fc:	fb058593          	addi	a1,a1,-80 # 800085a8 <syscalls+0x168>
    80003600:	0001d517          	auipc	a0,0x1d
    80003604:	06050513          	addi	a0,a0,96 # 80020660 <icache>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	5da080e7          	jalr	1498(ra) # 80000be2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003610:	0001d497          	auipc	s1,0x1d
    80003614:	07848493          	addi	s1,s1,120 # 80020688 <icache+0x28>
    80003618:	0001f997          	auipc	s3,0x1f
    8000361c:	b0098993          	addi	s3,s3,-1280 # 80022118 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003620:	00005917          	auipc	s2,0x5
    80003624:	f9090913          	addi	s2,s2,-112 # 800085b0 <syscalls+0x170>
    80003628:	85ca                	mv	a1,s2
    8000362a:	8526                	mv	a0,s1
    8000362c:	00001097          	auipc	ra,0x1
    80003630:	e36080e7          	jalr	-458(ra) # 80004462 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003634:	08848493          	addi	s1,s1,136
    80003638:	ff3498e3          	bne	s1,s3,80003628 <iinit+0x3e>
}
    8000363c:	70a2                	ld	ra,40(sp)
    8000363e:	7402                	ld	s0,32(sp)
    80003640:	64e2                	ld	s1,24(sp)
    80003642:	6942                	ld	s2,16(sp)
    80003644:	69a2                	ld	s3,8(sp)
    80003646:	6145                	addi	sp,sp,48
    80003648:	8082                	ret

000000008000364a <ialloc>:
{
    8000364a:	715d                	addi	sp,sp,-80
    8000364c:	e486                	sd	ra,72(sp)
    8000364e:	e0a2                	sd	s0,64(sp)
    80003650:	fc26                	sd	s1,56(sp)
    80003652:	f84a                	sd	s2,48(sp)
    80003654:	f44e                	sd	s3,40(sp)
    80003656:	f052                	sd	s4,32(sp)
    80003658:	ec56                	sd	s5,24(sp)
    8000365a:	e85a                	sd	s6,16(sp)
    8000365c:	e45e                	sd	s7,8(sp)
    8000365e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003660:	0001d717          	auipc	a4,0x1d
    80003664:	fec72703          	lw	a4,-20(a4) # 8002064c <sb+0xc>
    80003668:	4785                	li	a5,1
    8000366a:	04e7fa63          	bgeu	a5,a4,800036be <ialloc+0x74>
    8000366e:	8aaa                	mv	s5,a0
    80003670:	8bae                	mv	s7,a1
    80003672:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003674:	0001da17          	auipc	s4,0x1d
    80003678:	fcca0a13          	addi	s4,s4,-52 # 80020640 <sb>
    8000367c:	00048b1b          	sext.w	s6,s1
    80003680:	0044d793          	srli	a5,s1,0x4
    80003684:	018a2583          	lw	a1,24(s4)
    80003688:	9dbd                	addw	a1,a1,a5
    8000368a:	8556                	mv	a0,s5
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	954080e7          	jalr	-1708(ra) # 80002fe0 <bread>
    80003694:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003696:	05850993          	addi	s3,a0,88
    8000369a:	00f4f793          	andi	a5,s1,15
    8000369e:	079a                	slli	a5,a5,0x6
    800036a0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036a2:	00099783          	lh	a5,0(s3)
    800036a6:	c785                	beqz	a5,800036ce <ialloc+0x84>
    brelse(bp);
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	a68080e7          	jalr	-1432(ra) # 80003110 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036b0:	0485                	addi	s1,s1,1
    800036b2:	00ca2703          	lw	a4,12(s4)
    800036b6:	0004879b          	sext.w	a5,s1
    800036ba:	fce7e1e3          	bltu	a5,a4,8000367c <ialloc+0x32>
  panic("ialloc: no inodes");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	efa50513          	addi	a0,a0,-262 # 800085b8 <syscalls+0x178>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	f1a080e7          	jalr	-230(ra) # 800005e0 <panic>
      memset(dip, 0, sizeof(*dip));
    800036ce:	04000613          	li	a2,64
    800036d2:	4581                	li	a1,0
    800036d4:	854e                	mv	a0,s3
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	698080e7          	jalr	1688(ra) # 80000d6e <memset>
      dip->type = type;
    800036de:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036e2:	854a                	mv	a0,s2
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	c90080e7          	jalr	-880(ra) # 80004374 <log_write>
      brelse(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	a22080e7          	jalr	-1502(ra) # 80003110 <brelse>
      return iget(dev, inum);
    800036f6:	85da                	mv	a1,s6
    800036f8:	8556                	mv	a0,s5
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	db4080e7          	jalr	-588(ra) # 800034ae <iget>
}
    80003702:	60a6                	ld	ra,72(sp)
    80003704:	6406                	ld	s0,64(sp)
    80003706:	74e2                	ld	s1,56(sp)
    80003708:	7942                	ld	s2,48(sp)
    8000370a:	79a2                	ld	s3,40(sp)
    8000370c:	7a02                	ld	s4,32(sp)
    8000370e:	6ae2                	ld	s5,24(sp)
    80003710:	6b42                	ld	s6,16(sp)
    80003712:	6ba2                	ld	s7,8(sp)
    80003714:	6161                	addi	sp,sp,80
    80003716:	8082                	ret

0000000080003718 <iupdate>:
{
    80003718:	1101                	addi	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	e04a                	sd	s2,0(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003726:	415c                	lw	a5,4(a0)
    80003728:	0047d79b          	srliw	a5,a5,0x4
    8000372c:	0001d597          	auipc	a1,0x1d
    80003730:	f2c5a583          	lw	a1,-212(a1) # 80020658 <sb+0x18>
    80003734:	9dbd                	addw	a1,a1,a5
    80003736:	4108                	lw	a0,0(a0)
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	8a8080e7          	jalr	-1880(ra) # 80002fe0 <bread>
    80003740:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003742:	05850793          	addi	a5,a0,88
    80003746:	40c8                	lw	a0,4(s1)
    80003748:	893d                	andi	a0,a0,15
    8000374a:	051a                	slli	a0,a0,0x6
    8000374c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000374e:	04449703          	lh	a4,68(s1)
    80003752:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003756:	04649703          	lh	a4,70(s1)
    8000375a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000375e:	04849703          	lh	a4,72(s1)
    80003762:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003766:	04a49703          	lh	a4,74(s1)
    8000376a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000376e:	44f8                	lw	a4,76(s1)
    80003770:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003772:	03400613          	li	a2,52
    80003776:	05048593          	addi	a1,s1,80
    8000377a:	0531                	addi	a0,a0,12
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	64e080e7          	jalr	1614(ra) # 80000dca <memmove>
  log_write(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	bee080e7          	jalr	-1042(ra) # 80004374 <log_write>
  brelse(bp);
    8000378e:	854a                	mv	a0,s2
    80003790:	00000097          	auipc	ra,0x0
    80003794:	980080e7          	jalr	-1664(ra) # 80003110 <brelse>
}
    80003798:	60e2                	ld	ra,24(sp)
    8000379a:	6442                	ld	s0,16(sp)
    8000379c:	64a2                	ld	s1,8(sp)
    8000379e:	6902                	ld	s2,0(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret

00000000800037a4 <idup>:
{
    800037a4:	1101                	addi	sp,sp,-32
    800037a6:	ec06                	sd	ra,24(sp)
    800037a8:	e822                	sd	s0,16(sp)
    800037aa:	e426                	sd	s1,8(sp)
    800037ac:	1000                	addi	s0,sp,32
    800037ae:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037b0:	0001d517          	auipc	a0,0x1d
    800037b4:	eb050513          	addi	a0,a0,-336 # 80020660 <icache>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	4ba080e7          	jalr	1210(ra) # 80000c72 <acquire>
  ip->ref++;
    800037c0:	449c                	lw	a5,8(s1)
    800037c2:	2785                	addiw	a5,a5,1
    800037c4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037c6:	0001d517          	auipc	a0,0x1d
    800037ca:	e9a50513          	addi	a0,a0,-358 # 80020660 <icache>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	558080e7          	jalr	1368(ra) # 80000d26 <release>
}
    800037d6:	8526                	mv	a0,s1
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret

00000000800037e2 <ilock>:
{
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	e04a                	sd	s2,0(sp)
    800037ec:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ee:	c115                	beqz	a0,80003812 <ilock+0x30>
    800037f0:	84aa                	mv	s1,a0
    800037f2:	451c                	lw	a5,8(a0)
    800037f4:	00f05f63          	blez	a5,80003812 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037f8:	0541                	addi	a0,a0,16
    800037fa:	00001097          	auipc	ra,0x1
    800037fe:	ca2080e7          	jalr	-862(ra) # 8000449c <acquiresleep>
  if(ip->valid == 0){
    80003802:	40bc                	lw	a5,64(s1)
    80003804:	cf99                	beqz	a5,80003822 <ilock+0x40>
}
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6902                	ld	s2,0(sp)
    8000380e:	6105                	addi	sp,sp,32
    80003810:	8082                	ret
    panic("ilock");
    80003812:	00005517          	auipc	a0,0x5
    80003816:	dbe50513          	addi	a0,a0,-578 # 800085d0 <syscalls+0x190>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	dc6080e7          	jalr	-570(ra) # 800005e0 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003822:	40dc                	lw	a5,4(s1)
    80003824:	0047d79b          	srliw	a5,a5,0x4
    80003828:	0001d597          	auipc	a1,0x1d
    8000382c:	e305a583          	lw	a1,-464(a1) # 80020658 <sb+0x18>
    80003830:	9dbd                	addw	a1,a1,a5
    80003832:	4088                	lw	a0,0(s1)
    80003834:	fffff097          	auipc	ra,0xfffff
    80003838:	7ac080e7          	jalr	1964(ra) # 80002fe0 <bread>
    8000383c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000383e:	05850593          	addi	a1,a0,88
    80003842:	40dc                	lw	a5,4(s1)
    80003844:	8bbd                	andi	a5,a5,15
    80003846:	079a                	slli	a5,a5,0x6
    80003848:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000384a:	00059783          	lh	a5,0(a1)
    8000384e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003852:	00259783          	lh	a5,2(a1)
    80003856:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000385a:	00459783          	lh	a5,4(a1)
    8000385e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003862:	00659783          	lh	a5,6(a1)
    80003866:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000386a:	459c                	lw	a5,8(a1)
    8000386c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000386e:	03400613          	li	a2,52
    80003872:	05b1                	addi	a1,a1,12
    80003874:	05048513          	addi	a0,s1,80
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	552080e7          	jalr	1362(ra) # 80000dca <memmove>
    brelse(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00000097          	auipc	ra,0x0
    80003886:	88e080e7          	jalr	-1906(ra) # 80003110 <brelse>
    ip->valid = 1;
    8000388a:	4785                	li	a5,1
    8000388c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000388e:	04449783          	lh	a5,68(s1)
    80003892:	fbb5                	bnez	a5,80003806 <ilock+0x24>
      panic("ilock: no type");
    80003894:	00005517          	auipc	a0,0x5
    80003898:	d4450513          	addi	a0,a0,-700 # 800085d8 <syscalls+0x198>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	d44080e7          	jalr	-700(ra) # 800005e0 <panic>

00000000800038a4 <iunlock>:
{
    800038a4:	1101                	addi	sp,sp,-32
    800038a6:	ec06                	sd	ra,24(sp)
    800038a8:	e822                	sd	s0,16(sp)
    800038aa:	e426                	sd	s1,8(sp)
    800038ac:	e04a                	sd	s2,0(sp)
    800038ae:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038b0:	c905                	beqz	a0,800038e0 <iunlock+0x3c>
    800038b2:	84aa                	mv	s1,a0
    800038b4:	01050913          	addi	s2,a0,16
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	c7c080e7          	jalr	-900(ra) # 80004536 <holdingsleep>
    800038c2:	cd19                	beqz	a0,800038e0 <iunlock+0x3c>
    800038c4:	449c                	lw	a5,8(s1)
    800038c6:	00f05d63          	blez	a5,800038e0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038ca:	854a                	mv	a0,s2
    800038cc:	00001097          	auipc	ra,0x1
    800038d0:	c26080e7          	jalr	-986(ra) # 800044f2 <releasesleep>
}
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6902                	ld	s2,0(sp)
    800038dc:	6105                	addi	sp,sp,32
    800038de:	8082                	ret
    panic("iunlock");
    800038e0:	00005517          	auipc	a0,0x5
    800038e4:	d0850513          	addi	a0,a0,-760 # 800085e8 <syscalls+0x1a8>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	cf8080e7          	jalr	-776(ra) # 800005e0 <panic>

00000000800038f0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038f0:	7179                	addi	sp,sp,-48
    800038f2:	f406                	sd	ra,40(sp)
    800038f4:	f022                	sd	s0,32(sp)
    800038f6:	ec26                	sd	s1,24(sp)
    800038f8:	e84a                	sd	s2,16(sp)
    800038fa:	e44e                	sd	s3,8(sp)
    800038fc:	e052                	sd	s4,0(sp)
    800038fe:	1800                	addi	s0,sp,48
    80003900:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003902:	05050493          	addi	s1,a0,80
    80003906:	08050913          	addi	s2,a0,128
    8000390a:	a021                	j	80003912 <itrunc+0x22>
    8000390c:	0491                	addi	s1,s1,4
    8000390e:	01248d63          	beq	s1,s2,80003928 <itrunc+0x38>
    if(ip->addrs[i]){
    80003912:	408c                	lw	a1,0(s1)
    80003914:	dde5                	beqz	a1,8000390c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003916:	0009a503          	lw	a0,0(s3)
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	90c080e7          	jalr	-1780(ra) # 80003226 <bfree>
      ip->addrs[i] = 0;
    80003922:	0004a023          	sw	zero,0(s1)
    80003926:	b7dd                	j	8000390c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003928:	0809a583          	lw	a1,128(s3)
    8000392c:	e185                	bnez	a1,8000394c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000392e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003932:	854e                	mv	a0,s3
    80003934:	00000097          	auipc	ra,0x0
    80003938:	de4080e7          	jalr	-540(ra) # 80003718 <iupdate>
}
    8000393c:	70a2                	ld	ra,40(sp)
    8000393e:	7402                	ld	s0,32(sp)
    80003940:	64e2                	ld	s1,24(sp)
    80003942:	6942                	ld	s2,16(sp)
    80003944:	69a2                	ld	s3,8(sp)
    80003946:	6a02                	ld	s4,0(sp)
    80003948:	6145                	addi	sp,sp,48
    8000394a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000394c:	0009a503          	lw	a0,0(s3)
    80003950:	fffff097          	auipc	ra,0xfffff
    80003954:	690080e7          	jalr	1680(ra) # 80002fe0 <bread>
    80003958:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000395a:	05850493          	addi	s1,a0,88
    8000395e:	45850913          	addi	s2,a0,1112
    80003962:	a021                	j	8000396a <itrunc+0x7a>
    80003964:	0491                	addi	s1,s1,4
    80003966:	01248b63          	beq	s1,s2,8000397c <itrunc+0x8c>
      if(a[j])
    8000396a:	408c                	lw	a1,0(s1)
    8000396c:	dde5                	beqz	a1,80003964 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000396e:	0009a503          	lw	a0,0(s3)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	8b4080e7          	jalr	-1868(ra) # 80003226 <bfree>
    8000397a:	b7ed                	j	80003964 <itrunc+0x74>
    brelse(bp);
    8000397c:	8552                	mv	a0,s4
    8000397e:	fffff097          	auipc	ra,0xfffff
    80003982:	792080e7          	jalr	1938(ra) # 80003110 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003986:	0809a583          	lw	a1,128(s3)
    8000398a:	0009a503          	lw	a0,0(s3)
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	898080e7          	jalr	-1896(ra) # 80003226 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003996:	0809a023          	sw	zero,128(s3)
    8000399a:	bf51                	j	8000392e <itrunc+0x3e>

000000008000399c <iput>:
{
    8000399c:	1101                	addi	sp,sp,-32
    8000399e:	ec06                	sd	ra,24(sp)
    800039a0:	e822                	sd	s0,16(sp)
    800039a2:	e426                	sd	s1,8(sp)
    800039a4:	e04a                	sd	s2,0(sp)
    800039a6:	1000                	addi	s0,sp,32
    800039a8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039aa:	0001d517          	auipc	a0,0x1d
    800039ae:	cb650513          	addi	a0,a0,-842 # 80020660 <icache>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	2c0080e7          	jalr	704(ra) # 80000c72 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ba:	4498                	lw	a4,8(s1)
    800039bc:	4785                	li	a5,1
    800039be:	02f70363          	beq	a4,a5,800039e4 <iput+0x48>
  ip->ref--;
    800039c2:	449c                	lw	a5,8(s1)
    800039c4:	37fd                	addiw	a5,a5,-1
    800039c6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039c8:	0001d517          	auipc	a0,0x1d
    800039cc:	c9850513          	addi	a0,a0,-872 # 80020660 <icache>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	356080e7          	jalr	854(ra) # 80000d26 <release>
}
    800039d8:	60e2                	ld	ra,24(sp)
    800039da:	6442                	ld	s0,16(sp)
    800039dc:	64a2                	ld	s1,8(sp)
    800039de:	6902                	ld	s2,0(sp)
    800039e0:	6105                	addi	sp,sp,32
    800039e2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039e4:	40bc                	lw	a5,64(s1)
    800039e6:	dff1                	beqz	a5,800039c2 <iput+0x26>
    800039e8:	04a49783          	lh	a5,74(s1)
    800039ec:	fbf9                	bnez	a5,800039c2 <iput+0x26>
    acquiresleep(&ip->lock);
    800039ee:	01048913          	addi	s2,s1,16
    800039f2:	854a                	mv	a0,s2
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	aa8080e7          	jalr	-1368(ra) # 8000449c <acquiresleep>
    release(&icache.lock);
    800039fc:	0001d517          	auipc	a0,0x1d
    80003a00:	c6450513          	addi	a0,a0,-924 # 80020660 <icache>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	322080e7          	jalr	802(ra) # 80000d26 <release>
    itrunc(ip);
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	ee2080e7          	jalr	-286(ra) # 800038f0 <itrunc>
    ip->type = 0;
    80003a16:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a1a:	8526                	mv	a0,s1
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	cfc080e7          	jalr	-772(ra) # 80003718 <iupdate>
    ip->valid = 0;
    80003a24:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a28:	854a                	mv	a0,s2
    80003a2a:	00001097          	auipc	ra,0x1
    80003a2e:	ac8080e7          	jalr	-1336(ra) # 800044f2 <releasesleep>
    acquire(&icache.lock);
    80003a32:	0001d517          	auipc	a0,0x1d
    80003a36:	c2e50513          	addi	a0,a0,-978 # 80020660 <icache>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	238080e7          	jalr	568(ra) # 80000c72 <acquire>
    80003a42:	b741                	j	800039c2 <iput+0x26>

0000000080003a44 <iunlockput>:
{
    80003a44:	1101                	addi	sp,sp,-32
    80003a46:	ec06                	sd	ra,24(sp)
    80003a48:	e822                	sd	s0,16(sp)
    80003a4a:	e426                	sd	s1,8(sp)
    80003a4c:	1000                	addi	s0,sp,32
    80003a4e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	e54080e7          	jalr	-428(ra) # 800038a4 <iunlock>
  iput(ip);
    80003a58:	8526                	mv	a0,s1
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	f42080e7          	jalr	-190(ra) # 8000399c <iput>
}
    80003a62:	60e2                	ld	ra,24(sp)
    80003a64:	6442                	ld	s0,16(sp)
    80003a66:	64a2                	ld	s1,8(sp)
    80003a68:	6105                	addi	sp,sp,32
    80003a6a:	8082                	ret

0000000080003a6c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a6c:	1141                	addi	sp,sp,-16
    80003a6e:	e422                	sd	s0,8(sp)
    80003a70:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a72:	411c                	lw	a5,0(a0)
    80003a74:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a76:	415c                	lw	a5,4(a0)
    80003a78:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a7a:	04451783          	lh	a5,68(a0)
    80003a7e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a82:	04a51783          	lh	a5,74(a0)
    80003a86:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a8a:	04c56783          	lwu	a5,76(a0)
    80003a8e:	e99c                	sd	a5,16(a1)
}
    80003a90:	6422                	ld	s0,8(sp)
    80003a92:	0141                	addi	sp,sp,16
    80003a94:	8082                	ret

0000000080003a96 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a96:	457c                	lw	a5,76(a0)
    80003a98:	0ed7e863          	bltu	a5,a3,80003b88 <readi+0xf2>
{
    80003a9c:	7159                	addi	sp,sp,-112
    80003a9e:	f486                	sd	ra,104(sp)
    80003aa0:	f0a2                	sd	s0,96(sp)
    80003aa2:	eca6                	sd	s1,88(sp)
    80003aa4:	e8ca                	sd	s2,80(sp)
    80003aa6:	e4ce                	sd	s3,72(sp)
    80003aa8:	e0d2                	sd	s4,64(sp)
    80003aaa:	fc56                	sd	s5,56(sp)
    80003aac:	f85a                	sd	s6,48(sp)
    80003aae:	f45e                	sd	s7,40(sp)
    80003ab0:	f062                	sd	s8,32(sp)
    80003ab2:	ec66                	sd	s9,24(sp)
    80003ab4:	e86a                	sd	s10,16(sp)
    80003ab6:	e46e                	sd	s11,8(sp)
    80003ab8:	1880                	addi	s0,sp,112
    80003aba:	8baa                	mv	s7,a0
    80003abc:	8c2e                	mv	s8,a1
    80003abe:	8ab2                	mv	s5,a2
    80003ac0:	84b6                	mv	s1,a3
    80003ac2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ac4:	9f35                	addw	a4,a4,a3
    return 0;
    80003ac6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ac8:	08d76f63          	bltu	a4,a3,80003b66 <readi+0xd0>
  if(off + n > ip->size)
    80003acc:	00e7f463          	bgeu	a5,a4,80003ad4 <readi+0x3e>
    n = ip->size - off;
    80003ad0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad4:	0a0b0863          	beqz	s6,80003b84 <readi+0xee>
    80003ad8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ada:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ade:	5cfd                	li	s9,-1
    80003ae0:	a82d                	j	80003b1a <readi+0x84>
    80003ae2:	020a1d93          	slli	s11,s4,0x20
    80003ae6:	020ddd93          	srli	s11,s11,0x20
    80003aea:	05890793          	addi	a5,s2,88
    80003aee:	86ee                	mv	a3,s11
    80003af0:	963e                	add	a2,a2,a5
    80003af2:	85d6                	mv	a1,s5
    80003af4:	8562                	mv	a0,s8
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	9ee080e7          	jalr	-1554(ra) # 800024e4 <either_copyout>
    80003afe:	05950d63          	beq	a0,s9,80003b58 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b02:	854a                	mv	a0,s2
    80003b04:	fffff097          	auipc	ra,0xfffff
    80003b08:	60c080e7          	jalr	1548(ra) # 80003110 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0c:	013a09bb          	addw	s3,s4,s3
    80003b10:	009a04bb          	addw	s1,s4,s1
    80003b14:	9aee                	add	s5,s5,s11
    80003b16:	0569f663          	bgeu	s3,s6,80003b62 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b1a:	000ba903          	lw	s2,0(s7)
    80003b1e:	00a4d59b          	srliw	a1,s1,0xa
    80003b22:	855e                	mv	a0,s7
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	8b0080e7          	jalr	-1872(ra) # 800033d4 <bmap>
    80003b2c:	0005059b          	sext.w	a1,a0
    80003b30:	854a                	mv	a0,s2
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	4ae080e7          	jalr	1198(ra) # 80002fe0 <bread>
    80003b3a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3c:	3ff4f613          	andi	a2,s1,1023
    80003b40:	40cd07bb          	subw	a5,s10,a2
    80003b44:	413b073b          	subw	a4,s6,s3
    80003b48:	8a3e                	mv	s4,a5
    80003b4a:	2781                	sext.w	a5,a5
    80003b4c:	0007069b          	sext.w	a3,a4
    80003b50:	f8f6f9e3          	bgeu	a3,a5,80003ae2 <readi+0x4c>
    80003b54:	8a3a                	mv	s4,a4
    80003b56:	b771                	j	80003ae2 <readi+0x4c>
      brelse(bp);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	5b6080e7          	jalr	1462(ra) # 80003110 <brelse>
  }
  return tot;
    80003b62:	0009851b          	sext.w	a0,s3
}
    80003b66:	70a6                	ld	ra,104(sp)
    80003b68:	7406                	ld	s0,96(sp)
    80003b6a:	64e6                	ld	s1,88(sp)
    80003b6c:	6946                	ld	s2,80(sp)
    80003b6e:	69a6                	ld	s3,72(sp)
    80003b70:	6a06                	ld	s4,64(sp)
    80003b72:	7ae2                	ld	s5,56(sp)
    80003b74:	7b42                	ld	s6,48(sp)
    80003b76:	7ba2                	ld	s7,40(sp)
    80003b78:	7c02                	ld	s8,32(sp)
    80003b7a:	6ce2                	ld	s9,24(sp)
    80003b7c:	6d42                	ld	s10,16(sp)
    80003b7e:	6da2                	ld	s11,8(sp)
    80003b80:	6165                	addi	sp,sp,112
    80003b82:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b84:	89da                	mv	s3,s6
    80003b86:	bff1                	j	80003b62 <readi+0xcc>
    return 0;
    80003b88:	4501                	li	a0,0
}
    80003b8a:	8082                	ret

0000000080003b8c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b8c:	457c                	lw	a5,76(a0)
    80003b8e:	10d7e663          	bltu	a5,a3,80003c9a <writei+0x10e>
{
    80003b92:	7159                	addi	sp,sp,-112
    80003b94:	f486                	sd	ra,104(sp)
    80003b96:	f0a2                	sd	s0,96(sp)
    80003b98:	eca6                	sd	s1,88(sp)
    80003b9a:	e8ca                	sd	s2,80(sp)
    80003b9c:	e4ce                	sd	s3,72(sp)
    80003b9e:	e0d2                	sd	s4,64(sp)
    80003ba0:	fc56                	sd	s5,56(sp)
    80003ba2:	f85a                	sd	s6,48(sp)
    80003ba4:	f45e                	sd	s7,40(sp)
    80003ba6:	f062                	sd	s8,32(sp)
    80003ba8:	ec66                	sd	s9,24(sp)
    80003baa:	e86a                	sd	s10,16(sp)
    80003bac:	e46e                	sd	s11,8(sp)
    80003bae:	1880                	addi	s0,sp,112
    80003bb0:	8baa                	mv	s7,a0
    80003bb2:	8c2e                	mv	s8,a1
    80003bb4:	8ab2                	mv	s5,a2
    80003bb6:	8936                	mv	s2,a3
    80003bb8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bba:	00e687bb          	addw	a5,a3,a4
    80003bbe:	0ed7e063          	bltu	a5,a3,80003c9e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bc2:	00043737          	lui	a4,0x43
    80003bc6:	0cf76e63          	bltu	a4,a5,80003ca2 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bca:	0a0b0763          	beqz	s6,80003c78 <writei+0xec>
    80003bce:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bd4:	5cfd                	li	s9,-1
    80003bd6:	a091                	j	80003c1a <writei+0x8e>
    80003bd8:	02099d93          	slli	s11,s3,0x20
    80003bdc:	020ddd93          	srli	s11,s11,0x20
    80003be0:	05848793          	addi	a5,s1,88
    80003be4:	86ee                	mv	a3,s11
    80003be6:	8656                	mv	a2,s5
    80003be8:	85e2                	mv	a1,s8
    80003bea:	953e                	add	a0,a0,a5
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	94e080e7          	jalr	-1714(ra) # 8000253a <either_copyin>
    80003bf4:	07950263          	beq	a0,s9,80003c58 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	77a080e7          	jalr	1914(ra) # 80004374 <log_write>
    brelse(bp);
    80003c02:	8526                	mv	a0,s1
    80003c04:	fffff097          	auipc	ra,0xfffff
    80003c08:	50c080e7          	jalr	1292(ra) # 80003110 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c0c:	01498a3b          	addw	s4,s3,s4
    80003c10:	0129893b          	addw	s2,s3,s2
    80003c14:	9aee                	add	s5,s5,s11
    80003c16:	056a7663          	bgeu	s4,s6,80003c62 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c1a:	000ba483          	lw	s1,0(s7)
    80003c1e:	00a9559b          	srliw	a1,s2,0xa
    80003c22:	855e                	mv	a0,s7
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	7b0080e7          	jalr	1968(ra) # 800033d4 <bmap>
    80003c2c:	0005059b          	sext.w	a1,a0
    80003c30:	8526                	mv	a0,s1
    80003c32:	fffff097          	auipc	ra,0xfffff
    80003c36:	3ae080e7          	jalr	942(ra) # 80002fe0 <bread>
    80003c3a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3c:	3ff97513          	andi	a0,s2,1023
    80003c40:	40ad07bb          	subw	a5,s10,a0
    80003c44:	414b073b          	subw	a4,s6,s4
    80003c48:	89be                	mv	s3,a5
    80003c4a:	2781                	sext.w	a5,a5
    80003c4c:	0007069b          	sext.w	a3,a4
    80003c50:	f8f6f4e3          	bgeu	a3,a5,80003bd8 <writei+0x4c>
    80003c54:	89ba                	mv	s3,a4
    80003c56:	b749                	j	80003bd8 <writei+0x4c>
      brelse(bp);
    80003c58:	8526                	mv	a0,s1
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	4b6080e7          	jalr	1206(ra) # 80003110 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c62:	04cba783          	lw	a5,76(s7)
    80003c66:	0127f463          	bgeu	a5,s2,80003c6e <writei+0xe2>
      ip->size = off;
    80003c6a:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c6e:	855e                	mv	a0,s7
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	aa8080e7          	jalr	-1368(ra) # 80003718 <iupdate>
  }

  return n;
    80003c78:	000b051b          	sext.w	a0,s6
}
    80003c7c:	70a6                	ld	ra,104(sp)
    80003c7e:	7406                	ld	s0,96(sp)
    80003c80:	64e6                	ld	s1,88(sp)
    80003c82:	6946                	ld	s2,80(sp)
    80003c84:	69a6                	ld	s3,72(sp)
    80003c86:	6a06                	ld	s4,64(sp)
    80003c88:	7ae2                	ld	s5,56(sp)
    80003c8a:	7b42                	ld	s6,48(sp)
    80003c8c:	7ba2                	ld	s7,40(sp)
    80003c8e:	7c02                	ld	s8,32(sp)
    80003c90:	6ce2                	ld	s9,24(sp)
    80003c92:	6d42                	ld	s10,16(sp)
    80003c94:	6da2                	ld	s11,8(sp)
    80003c96:	6165                	addi	sp,sp,112
    80003c98:	8082                	ret
    return -1;
    80003c9a:	557d                	li	a0,-1
}
    80003c9c:	8082                	ret
    return -1;
    80003c9e:	557d                	li	a0,-1
    80003ca0:	bff1                	j	80003c7c <writei+0xf0>
    return -1;
    80003ca2:	557d                	li	a0,-1
    80003ca4:	bfe1                	j	80003c7c <writei+0xf0>

0000000080003ca6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ca6:	1141                	addi	sp,sp,-16
    80003ca8:	e406                	sd	ra,8(sp)
    80003caa:	e022                	sd	s0,0(sp)
    80003cac:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cae:	4639                	li	a2,14
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	196080e7          	jalr	406(ra) # 80000e46 <strncmp>
}
    80003cb8:	60a2                	ld	ra,8(sp)
    80003cba:	6402                	ld	s0,0(sp)
    80003cbc:	0141                	addi	sp,sp,16
    80003cbe:	8082                	ret

0000000080003cc0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cc0:	7139                	addi	sp,sp,-64
    80003cc2:	fc06                	sd	ra,56(sp)
    80003cc4:	f822                	sd	s0,48(sp)
    80003cc6:	f426                	sd	s1,40(sp)
    80003cc8:	f04a                	sd	s2,32(sp)
    80003cca:	ec4e                	sd	s3,24(sp)
    80003ccc:	e852                	sd	s4,16(sp)
    80003cce:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cd0:	04451703          	lh	a4,68(a0)
    80003cd4:	4785                	li	a5,1
    80003cd6:	00f71a63          	bne	a4,a5,80003cea <dirlookup+0x2a>
    80003cda:	892a                	mv	s2,a0
    80003cdc:	89ae                	mv	s3,a1
    80003cde:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce0:	457c                	lw	a5,76(a0)
    80003ce2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ce4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce6:	e79d                	bnez	a5,80003d14 <dirlookup+0x54>
    80003ce8:	a8a5                	j	80003d60 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cea:	00005517          	auipc	a0,0x5
    80003cee:	90650513          	addi	a0,a0,-1786 # 800085f0 <syscalls+0x1b0>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	8ee080e7          	jalr	-1810(ra) # 800005e0 <panic>
      panic("dirlookup read");
    80003cfa:	00005517          	auipc	a0,0x5
    80003cfe:	90e50513          	addi	a0,a0,-1778 # 80008608 <syscalls+0x1c8>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	8de080e7          	jalr	-1826(ra) # 800005e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0a:	24c1                	addiw	s1,s1,16
    80003d0c:	04c92783          	lw	a5,76(s2)
    80003d10:	04f4f763          	bgeu	s1,a5,80003d5e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d14:	4741                	li	a4,16
    80003d16:	86a6                	mv	a3,s1
    80003d18:	fc040613          	addi	a2,s0,-64
    80003d1c:	4581                	li	a1,0
    80003d1e:	854a                	mv	a0,s2
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	d76080e7          	jalr	-650(ra) # 80003a96 <readi>
    80003d28:	47c1                	li	a5,16
    80003d2a:	fcf518e3          	bne	a0,a5,80003cfa <dirlookup+0x3a>
    if(de.inum == 0)
    80003d2e:	fc045783          	lhu	a5,-64(s0)
    80003d32:	dfe1                	beqz	a5,80003d0a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d34:	fc240593          	addi	a1,s0,-62
    80003d38:	854e                	mv	a0,s3
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	f6c080e7          	jalr	-148(ra) # 80003ca6 <namecmp>
    80003d42:	f561                	bnez	a0,80003d0a <dirlookup+0x4a>
      if(poff)
    80003d44:	000a0463          	beqz	s4,80003d4c <dirlookup+0x8c>
        *poff = off;
    80003d48:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d4c:	fc045583          	lhu	a1,-64(s0)
    80003d50:	00092503          	lw	a0,0(s2)
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	75a080e7          	jalr	1882(ra) # 800034ae <iget>
    80003d5c:	a011                	j	80003d60 <dirlookup+0xa0>
  return 0;
    80003d5e:	4501                	li	a0,0
}
    80003d60:	70e2                	ld	ra,56(sp)
    80003d62:	7442                	ld	s0,48(sp)
    80003d64:	74a2                	ld	s1,40(sp)
    80003d66:	7902                	ld	s2,32(sp)
    80003d68:	69e2                	ld	s3,24(sp)
    80003d6a:	6a42                	ld	s4,16(sp)
    80003d6c:	6121                	addi	sp,sp,64
    80003d6e:	8082                	ret

0000000080003d70 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d70:	711d                	addi	sp,sp,-96
    80003d72:	ec86                	sd	ra,88(sp)
    80003d74:	e8a2                	sd	s0,80(sp)
    80003d76:	e4a6                	sd	s1,72(sp)
    80003d78:	e0ca                	sd	s2,64(sp)
    80003d7a:	fc4e                	sd	s3,56(sp)
    80003d7c:	f852                	sd	s4,48(sp)
    80003d7e:	f456                	sd	s5,40(sp)
    80003d80:	f05a                	sd	s6,32(sp)
    80003d82:	ec5e                	sd	s7,24(sp)
    80003d84:	e862                	sd	s8,16(sp)
    80003d86:	e466                	sd	s9,8(sp)
    80003d88:	1080                	addi	s0,sp,96
    80003d8a:	84aa                	mv	s1,a0
    80003d8c:	8aae                	mv	s5,a1
    80003d8e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d90:	00054703          	lbu	a4,0(a0)
    80003d94:	02f00793          	li	a5,47
    80003d98:	02f70363          	beq	a4,a5,80003dbe <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d9c:	ffffe097          	auipc	ra,0xffffe
    80003da0:	ca2080e7          	jalr	-862(ra) # 80001a3e <myproc>
    80003da4:	16053503          	ld	a0,352(a0)
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	9fc080e7          	jalr	-1540(ra) # 800037a4 <idup>
    80003db0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003db2:	02f00913          	li	s2,47
  len = path - s;
    80003db6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003db8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dba:	4b85                	li	s7,1
    80003dbc:	a865                	j	80003e74 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dbe:	4585                	li	a1,1
    80003dc0:	4505                	li	a0,1
    80003dc2:	fffff097          	auipc	ra,0xfffff
    80003dc6:	6ec080e7          	jalr	1772(ra) # 800034ae <iget>
    80003dca:	89aa                	mv	s3,a0
    80003dcc:	b7dd                	j	80003db2 <namex+0x42>
      iunlockput(ip);
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	c74080e7          	jalr	-908(ra) # 80003a44 <iunlockput>
      return 0;
    80003dd8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dda:	854e                	mv	a0,s3
    80003ddc:	60e6                	ld	ra,88(sp)
    80003dde:	6446                	ld	s0,80(sp)
    80003de0:	64a6                	ld	s1,72(sp)
    80003de2:	6906                	ld	s2,64(sp)
    80003de4:	79e2                	ld	s3,56(sp)
    80003de6:	7a42                	ld	s4,48(sp)
    80003de8:	7aa2                	ld	s5,40(sp)
    80003dea:	7b02                	ld	s6,32(sp)
    80003dec:	6be2                	ld	s7,24(sp)
    80003dee:	6c42                	ld	s8,16(sp)
    80003df0:	6ca2                	ld	s9,8(sp)
    80003df2:	6125                	addi	sp,sp,96
    80003df4:	8082                	ret
      iunlock(ip);
    80003df6:	854e                	mv	a0,s3
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	aac080e7          	jalr	-1364(ra) # 800038a4 <iunlock>
      return ip;
    80003e00:	bfe9                	j	80003dda <namex+0x6a>
      iunlockput(ip);
    80003e02:	854e                	mv	a0,s3
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	c40080e7          	jalr	-960(ra) # 80003a44 <iunlockput>
      return 0;
    80003e0c:	89e6                	mv	s3,s9
    80003e0e:	b7f1                	j	80003dda <namex+0x6a>
  len = path - s;
    80003e10:	40b48633          	sub	a2,s1,a1
    80003e14:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e18:	099c5463          	bge	s8,s9,80003ea0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e1c:	4639                	li	a2,14
    80003e1e:	8552                	mv	a0,s4
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	faa080e7          	jalr	-86(ra) # 80000dca <memmove>
  while(*path == '/')
    80003e28:	0004c783          	lbu	a5,0(s1)
    80003e2c:	01279763          	bne	a5,s2,80003e3a <namex+0xca>
    path++;
    80003e30:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	ff278de3          	beq	a5,s2,80003e30 <namex+0xc0>
    ilock(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	9a6080e7          	jalr	-1626(ra) # 800037e2 <ilock>
    if(ip->type != T_DIR){
    80003e44:	04499783          	lh	a5,68(s3)
    80003e48:	f97793e3          	bne	a5,s7,80003dce <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e4c:	000a8563          	beqz	s5,80003e56 <namex+0xe6>
    80003e50:	0004c783          	lbu	a5,0(s1)
    80003e54:	d3cd                	beqz	a5,80003df6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e56:	865a                	mv	a2,s6
    80003e58:	85d2                	mv	a1,s4
    80003e5a:	854e                	mv	a0,s3
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	e64080e7          	jalr	-412(ra) # 80003cc0 <dirlookup>
    80003e64:	8caa                	mv	s9,a0
    80003e66:	dd51                	beqz	a0,80003e02 <namex+0x92>
    iunlockput(ip);
    80003e68:	854e                	mv	a0,s3
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	bda080e7          	jalr	-1062(ra) # 80003a44 <iunlockput>
    ip = next;
    80003e72:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e74:	0004c783          	lbu	a5,0(s1)
    80003e78:	05279763          	bne	a5,s2,80003ec6 <namex+0x156>
    path++;
    80003e7c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e7e:	0004c783          	lbu	a5,0(s1)
    80003e82:	ff278de3          	beq	a5,s2,80003e7c <namex+0x10c>
  if(*path == 0)
    80003e86:	c79d                	beqz	a5,80003eb4 <namex+0x144>
    path++;
    80003e88:	85a6                	mv	a1,s1
  len = path - s;
    80003e8a:	8cda                	mv	s9,s6
    80003e8c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e8e:	01278963          	beq	a5,s2,80003ea0 <namex+0x130>
    80003e92:	dfbd                	beqz	a5,80003e10 <namex+0xa0>
    path++;
    80003e94:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e96:	0004c783          	lbu	a5,0(s1)
    80003e9a:	ff279ce3          	bne	a5,s2,80003e92 <namex+0x122>
    80003e9e:	bf8d                	j	80003e10 <namex+0xa0>
    memmove(name, s, len);
    80003ea0:	2601                	sext.w	a2,a2
    80003ea2:	8552                	mv	a0,s4
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	f26080e7          	jalr	-218(ra) # 80000dca <memmove>
    name[len] = 0;
    80003eac:	9cd2                	add	s9,s9,s4
    80003eae:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003eb2:	bf9d                	j	80003e28 <namex+0xb8>
  if(nameiparent){
    80003eb4:	f20a83e3          	beqz	s5,80003dda <namex+0x6a>
    iput(ip);
    80003eb8:	854e                	mv	a0,s3
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	ae2080e7          	jalr	-1310(ra) # 8000399c <iput>
    return 0;
    80003ec2:	4981                	li	s3,0
    80003ec4:	bf19                	j	80003dda <namex+0x6a>
  if(*path == 0)
    80003ec6:	d7fd                	beqz	a5,80003eb4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	85a6                	mv	a1,s1
    80003ece:	b7d1                	j	80003e92 <namex+0x122>

0000000080003ed0 <dirlink>:
{
    80003ed0:	7139                	addi	sp,sp,-64
    80003ed2:	fc06                	sd	ra,56(sp)
    80003ed4:	f822                	sd	s0,48(sp)
    80003ed6:	f426                	sd	s1,40(sp)
    80003ed8:	f04a                	sd	s2,32(sp)
    80003eda:	ec4e                	sd	s3,24(sp)
    80003edc:	e852                	sd	s4,16(sp)
    80003ede:	0080                	addi	s0,sp,64
    80003ee0:	892a                	mv	s2,a0
    80003ee2:	8a2e                	mv	s4,a1
    80003ee4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ee6:	4601                	li	a2,0
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	dd8080e7          	jalr	-552(ra) # 80003cc0 <dirlookup>
    80003ef0:	e93d                	bnez	a0,80003f66 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef2:	04c92483          	lw	s1,76(s2)
    80003ef6:	c49d                	beqz	s1,80003f24 <dirlink+0x54>
    80003ef8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efa:	4741                	li	a4,16
    80003efc:	86a6                	mv	a3,s1
    80003efe:	fc040613          	addi	a2,s0,-64
    80003f02:	4581                	li	a1,0
    80003f04:	854a                	mv	a0,s2
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	b90080e7          	jalr	-1136(ra) # 80003a96 <readi>
    80003f0e:	47c1                	li	a5,16
    80003f10:	06f51163          	bne	a0,a5,80003f72 <dirlink+0xa2>
    if(de.inum == 0)
    80003f14:	fc045783          	lhu	a5,-64(s0)
    80003f18:	c791                	beqz	a5,80003f24 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1a:	24c1                	addiw	s1,s1,16
    80003f1c:	04c92783          	lw	a5,76(s2)
    80003f20:	fcf4ede3          	bltu	s1,a5,80003efa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f24:	4639                	li	a2,14
    80003f26:	85d2                	mv	a1,s4
    80003f28:	fc240513          	addi	a0,s0,-62
    80003f2c:	ffffd097          	auipc	ra,0xffffd
    80003f30:	f56080e7          	jalr	-170(ra) # 80000e82 <strncpy>
  de.inum = inum;
    80003f34:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f38:	4741                	li	a4,16
    80003f3a:	86a6                	mv	a3,s1
    80003f3c:	fc040613          	addi	a2,s0,-64
    80003f40:	4581                	li	a1,0
    80003f42:	854a                	mv	a0,s2
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	c48080e7          	jalr	-952(ra) # 80003b8c <writei>
    80003f4c:	872a                	mv	a4,a0
    80003f4e:	47c1                	li	a5,16
  return 0;
    80003f50:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f52:	02f71863          	bne	a4,a5,80003f82 <dirlink+0xb2>
}
    80003f56:	70e2                	ld	ra,56(sp)
    80003f58:	7442                	ld	s0,48(sp)
    80003f5a:	74a2                	ld	s1,40(sp)
    80003f5c:	7902                	ld	s2,32(sp)
    80003f5e:	69e2                	ld	s3,24(sp)
    80003f60:	6a42                	ld	s4,16(sp)
    80003f62:	6121                	addi	sp,sp,64
    80003f64:	8082                	ret
    iput(ip);
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	a36080e7          	jalr	-1482(ra) # 8000399c <iput>
    return -1;
    80003f6e:	557d                	li	a0,-1
    80003f70:	b7dd                	j	80003f56 <dirlink+0x86>
      panic("dirlink read");
    80003f72:	00004517          	auipc	a0,0x4
    80003f76:	6a650513          	addi	a0,a0,1702 # 80008618 <syscalls+0x1d8>
    80003f7a:	ffffc097          	auipc	ra,0xffffc
    80003f7e:	666080e7          	jalr	1638(ra) # 800005e0 <panic>
    panic("dirlink");
    80003f82:	00004517          	auipc	a0,0x4
    80003f86:	7b650513          	addi	a0,a0,1974 # 80008738 <syscalls+0x2f8>
    80003f8a:	ffffc097          	auipc	ra,0xffffc
    80003f8e:	656080e7          	jalr	1622(ra) # 800005e0 <panic>

0000000080003f92 <namei>:

struct inode*
namei(char *path)
{
    80003f92:	1101                	addi	sp,sp,-32
    80003f94:	ec06                	sd	ra,24(sp)
    80003f96:	e822                	sd	s0,16(sp)
    80003f98:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f9a:	fe040613          	addi	a2,s0,-32
    80003f9e:	4581                	li	a1,0
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	dd0080e7          	jalr	-560(ra) # 80003d70 <namex>
}
    80003fa8:	60e2                	ld	ra,24(sp)
    80003faa:	6442                	ld	s0,16(sp)
    80003fac:	6105                	addi	sp,sp,32
    80003fae:	8082                	ret

0000000080003fb0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fb0:	1141                	addi	sp,sp,-16
    80003fb2:	e406                	sd	ra,8(sp)
    80003fb4:	e022                	sd	s0,0(sp)
    80003fb6:	0800                	addi	s0,sp,16
    80003fb8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fba:	4585                	li	a1,1
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	db4080e7          	jalr	-588(ra) # 80003d70 <namex>
}
    80003fc4:	60a2                	ld	ra,8(sp)
    80003fc6:	6402                	ld	s0,0(sp)
    80003fc8:	0141                	addi	sp,sp,16
    80003fca:	8082                	ret

0000000080003fcc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fcc:	1101                	addi	sp,sp,-32
    80003fce:	ec06                	sd	ra,24(sp)
    80003fd0:	e822                	sd	s0,16(sp)
    80003fd2:	e426                	sd	s1,8(sp)
    80003fd4:	e04a                	sd	s2,0(sp)
    80003fd6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fd8:	0001e917          	auipc	s2,0x1e
    80003fdc:	13090913          	addi	s2,s2,304 # 80022108 <log>
    80003fe0:	01892583          	lw	a1,24(s2)
    80003fe4:	02892503          	lw	a0,40(s2)
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	ff8080e7          	jalr	-8(ra) # 80002fe0 <bread>
    80003ff0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ff2:	02c92683          	lw	a3,44(s2)
    80003ff6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ff8:	02d05763          	blez	a3,80004026 <write_head+0x5a>
    80003ffc:	0001e797          	auipc	a5,0x1e
    80004000:	13c78793          	addi	a5,a5,316 # 80022138 <log+0x30>
    80004004:	05c50713          	addi	a4,a0,92
    80004008:	36fd                	addiw	a3,a3,-1
    8000400a:	1682                	slli	a3,a3,0x20
    8000400c:	9281                	srli	a3,a3,0x20
    8000400e:	068a                	slli	a3,a3,0x2
    80004010:	0001e617          	auipc	a2,0x1e
    80004014:	12c60613          	addi	a2,a2,300 # 8002213c <log+0x34>
    80004018:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000401a:	4390                	lw	a2,0(a5)
    8000401c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000401e:	0791                	addi	a5,a5,4
    80004020:	0711                	addi	a4,a4,4
    80004022:	fed79ce3          	bne	a5,a3,8000401a <write_head+0x4e>
  }
  bwrite(buf);
    80004026:	8526                	mv	a0,s1
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	0aa080e7          	jalr	170(ra) # 800030d2 <bwrite>
  brelse(buf);
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	0de080e7          	jalr	222(ra) # 80003110 <brelse>
}
    8000403a:	60e2                	ld	ra,24(sp)
    8000403c:	6442                	ld	s0,16(sp)
    8000403e:	64a2                	ld	s1,8(sp)
    80004040:	6902                	ld	s2,0(sp)
    80004042:	6105                	addi	sp,sp,32
    80004044:	8082                	ret

0000000080004046 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004046:	0001e797          	auipc	a5,0x1e
    8000404a:	0ee7a783          	lw	a5,238(a5) # 80022134 <log+0x2c>
    8000404e:	0af05663          	blez	a5,800040fa <install_trans+0xb4>
{
    80004052:	7139                	addi	sp,sp,-64
    80004054:	fc06                	sd	ra,56(sp)
    80004056:	f822                	sd	s0,48(sp)
    80004058:	f426                	sd	s1,40(sp)
    8000405a:	f04a                	sd	s2,32(sp)
    8000405c:	ec4e                	sd	s3,24(sp)
    8000405e:	e852                	sd	s4,16(sp)
    80004060:	e456                	sd	s5,8(sp)
    80004062:	0080                	addi	s0,sp,64
    80004064:	0001ea97          	auipc	s5,0x1e
    80004068:	0d4a8a93          	addi	s5,s5,212 # 80022138 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000406c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000406e:	0001e997          	auipc	s3,0x1e
    80004072:	09a98993          	addi	s3,s3,154 # 80022108 <log>
    80004076:	0189a583          	lw	a1,24(s3)
    8000407a:	014585bb          	addw	a1,a1,s4
    8000407e:	2585                	addiw	a1,a1,1
    80004080:	0289a503          	lw	a0,40(s3)
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	f5c080e7          	jalr	-164(ra) # 80002fe0 <bread>
    8000408c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000408e:	000aa583          	lw	a1,0(s5)
    80004092:	0289a503          	lw	a0,40(s3)
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	f4a080e7          	jalr	-182(ra) # 80002fe0 <bread>
    8000409e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040a0:	40000613          	li	a2,1024
    800040a4:	05890593          	addi	a1,s2,88
    800040a8:	05850513          	addi	a0,a0,88
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	d1e080e7          	jalr	-738(ra) # 80000dca <memmove>
    bwrite(dbuf);  // write dst to disk
    800040b4:	8526                	mv	a0,s1
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	01c080e7          	jalr	28(ra) # 800030d2 <bwrite>
    bunpin(dbuf);
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	12a080e7          	jalr	298(ra) # 800031ea <bunpin>
    brelse(lbuf);
    800040c8:	854a                	mv	a0,s2
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	046080e7          	jalr	70(ra) # 80003110 <brelse>
    brelse(dbuf);
    800040d2:	8526                	mv	a0,s1
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	03c080e7          	jalr	60(ra) # 80003110 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040dc:	2a05                	addiw	s4,s4,1
    800040de:	0a91                	addi	s5,s5,4
    800040e0:	02c9a783          	lw	a5,44(s3)
    800040e4:	f8fa49e3          	blt	s4,a5,80004076 <install_trans+0x30>
}
    800040e8:	70e2                	ld	ra,56(sp)
    800040ea:	7442                	ld	s0,48(sp)
    800040ec:	74a2                	ld	s1,40(sp)
    800040ee:	7902                	ld	s2,32(sp)
    800040f0:	69e2                	ld	s3,24(sp)
    800040f2:	6a42                	ld	s4,16(sp)
    800040f4:	6aa2                	ld	s5,8(sp)
    800040f6:	6121                	addi	sp,sp,64
    800040f8:	8082                	ret
    800040fa:	8082                	ret

00000000800040fc <initlog>:
{
    800040fc:	7179                	addi	sp,sp,-48
    800040fe:	f406                	sd	ra,40(sp)
    80004100:	f022                	sd	s0,32(sp)
    80004102:	ec26                	sd	s1,24(sp)
    80004104:	e84a                	sd	s2,16(sp)
    80004106:	e44e                	sd	s3,8(sp)
    80004108:	1800                	addi	s0,sp,48
    8000410a:	892a                	mv	s2,a0
    8000410c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000410e:	0001e497          	auipc	s1,0x1e
    80004112:	ffa48493          	addi	s1,s1,-6 # 80022108 <log>
    80004116:	00004597          	auipc	a1,0x4
    8000411a:	51258593          	addi	a1,a1,1298 # 80008628 <syscalls+0x1e8>
    8000411e:	8526                	mv	a0,s1
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	ac2080e7          	jalr	-1342(ra) # 80000be2 <initlock>
  log.start = sb->logstart;
    80004128:	0149a583          	lw	a1,20(s3)
    8000412c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000412e:	0109a783          	lw	a5,16(s3)
    80004132:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004134:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004138:	854a                	mv	a0,s2
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	ea6080e7          	jalr	-346(ra) # 80002fe0 <bread>
  log.lh.n = lh->n;
    80004142:	4d34                	lw	a3,88(a0)
    80004144:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004146:	02d05563          	blez	a3,80004170 <initlog+0x74>
    8000414a:	05c50793          	addi	a5,a0,92
    8000414e:	0001e717          	auipc	a4,0x1e
    80004152:	fea70713          	addi	a4,a4,-22 # 80022138 <log+0x30>
    80004156:	36fd                	addiw	a3,a3,-1
    80004158:	1682                	slli	a3,a3,0x20
    8000415a:	9281                	srli	a3,a3,0x20
    8000415c:	068a                	slli	a3,a3,0x2
    8000415e:	06050613          	addi	a2,a0,96
    80004162:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004164:	4390                	lw	a2,0(a5)
    80004166:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004168:	0791                	addi	a5,a5,4
    8000416a:	0711                	addi	a4,a4,4
    8000416c:	fed79ce3          	bne	a5,a3,80004164 <initlog+0x68>
  brelse(buf);
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	fa0080e7          	jalr	-96(ra) # 80003110 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	ece080e7          	jalr	-306(ra) # 80004046 <install_trans>
  log.lh.n = 0;
    80004180:	0001e797          	auipc	a5,0x1e
    80004184:	fa07aa23          	sw	zero,-76(a5) # 80022134 <log+0x2c>
  write_head(); // clear the log
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	e44080e7          	jalr	-444(ra) # 80003fcc <write_head>
}
    80004190:	70a2                	ld	ra,40(sp)
    80004192:	7402                	ld	s0,32(sp)
    80004194:	64e2                	ld	s1,24(sp)
    80004196:	6942                	ld	s2,16(sp)
    80004198:	69a2                	ld	s3,8(sp)
    8000419a:	6145                	addi	sp,sp,48
    8000419c:	8082                	ret

000000008000419e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000419e:	1101                	addi	sp,sp,-32
    800041a0:	ec06                	sd	ra,24(sp)
    800041a2:	e822                	sd	s0,16(sp)
    800041a4:	e426                	sd	s1,8(sp)
    800041a6:	e04a                	sd	s2,0(sp)
    800041a8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041aa:	0001e517          	auipc	a0,0x1e
    800041ae:	f5e50513          	addi	a0,a0,-162 # 80022108 <log>
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	ac0080e7          	jalr	-1344(ra) # 80000c72 <acquire>
  while(1){
    if(log.committing){
    800041ba:	0001e497          	auipc	s1,0x1e
    800041be:	f4e48493          	addi	s1,s1,-178 # 80022108 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c2:	4979                	li	s2,30
    800041c4:	a039                	j	800041d2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041c6:	85a6                	mv	a1,s1
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	0c0080e7          	jalr	192(ra) # 8000228a <sleep>
    if(log.committing){
    800041d2:	50dc                	lw	a5,36(s1)
    800041d4:	fbed                	bnez	a5,800041c6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041d6:	509c                	lw	a5,32(s1)
    800041d8:	0017871b          	addiw	a4,a5,1
    800041dc:	0007069b          	sext.w	a3,a4
    800041e0:	0027179b          	slliw	a5,a4,0x2
    800041e4:	9fb9                	addw	a5,a5,a4
    800041e6:	0017979b          	slliw	a5,a5,0x1
    800041ea:	54d8                	lw	a4,44(s1)
    800041ec:	9fb9                	addw	a5,a5,a4
    800041ee:	00f95963          	bge	s2,a5,80004200 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041f2:	85a6                	mv	a1,s1
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	094080e7          	jalr	148(ra) # 8000228a <sleep>
    800041fe:	bfd1                	j	800041d2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004200:	0001e517          	auipc	a0,0x1e
    80004204:	f0850513          	addi	a0,a0,-248 # 80022108 <log>
    80004208:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	b1c080e7          	jalr	-1252(ra) # 80000d26 <release>
      break;
    }
  }
}
    80004212:	60e2                	ld	ra,24(sp)
    80004214:	6442                	ld	s0,16(sp)
    80004216:	64a2                	ld	s1,8(sp)
    80004218:	6902                	ld	s2,0(sp)
    8000421a:	6105                	addi	sp,sp,32
    8000421c:	8082                	ret

000000008000421e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000421e:	7139                	addi	sp,sp,-64
    80004220:	fc06                	sd	ra,56(sp)
    80004222:	f822                	sd	s0,48(sp)
    80004224:	f426                	sd	s1,40(sp)
    80004226:	f04a                	sd	s2,32(sp)
    80004228:	ec4e                	sd	s3,24(sp)
    8000422a:	e852                	sd	s4,16(sp)
    8000422c:	e456                	sd	s5,8(sp)
    8000422e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004230:	0001e497          	auipc	s1,0x1e
    80004234:	ed848493          	addi	s1,s1,-296 # 80022108 <log>
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffd097          	auipc	ra,0xffffd
    8000423e:	a38080e7          	jalr	-1480(ra) # 80000c72 <acquire>
  log.outstanding -= 1;
    80004242:	509c                	lw	a5,32(s1)
    80004244:	37fd                	addiw	a5,a5,-1
    80004246:	0007891b          	sext.w	s2,a5
    8000424a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000424c:	50dc                	lw	a5,36(s1)
    8000424e:	e7b9                	bnez	a5,8000429c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004250:	04091e63          	bnez	s2,800042ac <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004254:	0001e497          	auipc	s1,0x1e
    80004258:	eb448493          	addi	s1,s1,-332 # 80022108 <log>
    8000425c:	4785                	li	a5,1
    8000425e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	ac4080e7          	jalr	-1340(ra) # 80000d26 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000426a:	54dc                	lw	a5,44(s1)
    8000426c:	06f04763          	bgtz	a5,800042da <end_op+0xbc>
    acquire(&log.lock);
    80004270:	0001e497          	auipc	s1,0x1e
    80004274:	e9848493          	addi	s1,s1,-360 # 80022108 <log>
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	9f8080e7          	jalr	-1544(ra) # 80000c72 <acquire>
    log.committing = 0;
    80004282:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004286:	8526                	mv	a0,s1
    80004288:	ffffe097          	auipc	ra,0xffffe
    8000428c:	182080e7          	jalr	386(ra) # 8000240a <wakeup>
    release(&log.lock);
    80004290:	8526                	mv	a0,s1
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	a94080e7          	jalr	-1388(ra) # 80000d26 <release>
}
    8000429a:	a03d                	j	800042c8 <end_op+0xaa>
    panic("log.committing");
    8000429c:	00004517          	auipc	a0,0x4
    800042a0:	39450513          	addi	a0,a0,916 # 80008630 <syscalls+0x1f0>
    800042a4:	ffffc097          	auipc	ra,0xffffc
    800042a8:	33c080e7          	jalr	828(ra) # 800005e0 <panic>
    wakeup(&log);
    800042ac:	0001e497          	auipc	s1,0x1e
    800042b0:	e5c48493          	addi	s1,s1,-420 # 80022108 <log>
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffe097          	auipc	ra,0xffffe
    800042ba:	154080e7          	jalr	340(ra) # 8000240a <wakeup>
  release(&log.lock);
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	a66080e7          	jalr	-1434(ra) # 80000d26 <release>
}
    800042c8:	70e2                	ld	ra,56(sp)
    800042ca:	7442                	ld	s0,48(sp)
    800042cc:	74a2                	ld	s1,40(sp)
    800042ce:	7902                	ld	s2,32(sp)
    800042d0:	69e2                	ld	s3,24(sp)
    800042d2:	6a42                	ld	s4,16(sp)
    800042d4:	6aa2                	ld	s5,8(sp)
    800042d6:	6121                	addi	sp,sp,64
    800042d8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042da:	0001ea97          	auipc	s5,0x1e
    800042de:	e5ea8a93          	addi	s5,s5,-418 # 80022138 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042e2:	0001ea17          	auipc	s4,0x1e
    800042e6:	e26a0a13          	addi	s4,s4,-474 # 80022108 <log>
    800042ea:	018a2583          	lw	a1,24(s4)
    800042ee:	012585bb          	addw	a1,a1,s2
    800042f2:	2585                	addiw	a1,a1,1
    800042f4:	028a2503          	lw	a0,40(s4)
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	ce8080e7          	jalr	-792(ra) # 80002fe0 <bread>
    80004300:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004302:	000aa583          	lw	a1,0(s5)
    80004306:	028a2503          	lw	a0,40(s4)
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	cd6080e7          	jalr	-810(ra) # 80002fe0 <bread>
    80004312:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004314:	40000613          	li	a2,1024
    80004318:	05850593          	addi	a1,a0,88
    8000431c:	05848513          	addi	a0,s1,88
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	aaa080e7          	jalr	-1366(ra) # 80000dca <memmove>
    bwrite(to);  // write the log
    80004328:	8526                	mv	a0,s1
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	da8080e7          	jalr	-600(ra) # 800030d2 <bwrite>
    brelse(from);
    80004332:	854e                	mv	a0,s3
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	ddc080e7          	jalr	-548(ra) # 80003110 <brelse>
    brelse(to);
    8000433c:	8526                	mv	a0,s1
    8000433e:	fffff097          	auipc	ra,0xfffff
    80004342:	dd2080e7          	jalr	-558(ra) # 80003110 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004346:	2905                	addiw	s2,s2,1
    80004348:	0a91                	addi	s5,s5,4
    8000434a:	02ca2783          	lw	a5,44(s4)
    8000434e:	f8f94ee3          	blt	s2,a5,800042ea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004352:	00000097          	auipc	ra,0x0
    80004356:	c7a080e7          	jalr	-902(ra) # 80003fcc <write_head>
    install_trans(); // Now install writes to home locations
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	cec080e7          	jalr	-788(ra) # 80004046 <install_trans>
    log.lh.n = 0;
    80004362:	0001e797          	auipc	a5,0x1e
    80004366:	dc07a923          	sw	zero,-558(a5) # 80022134 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	c62080e7          	jalr	-926(ra) # 80003fcc <write_head>
    80004372:	bdfd                	j	80004270 <end_op+0x52>

0000000080004374 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004374:	1101                	addi	sp,sp,-32
    80004376:	ec06                	sd	ra,24(sp)
    80004378:	e822                	sd	s0,16(sp)
    8000437a:	e426                	sd	s1,8(sp)
    8000437c:	e04a                	sd	s2,0(sp)
    8000437e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004380:	0001e717          	auipc	a4,0x1e
    80004384:	db472703          	lw	a4,-588(a4) # 80022134 <log+0x2c>
    80004388:	47f5                	li	a5,29
    8000438a:	08e7c063          	blt	a5,a4,8000440a <log_write+0x96>
    8000438e:	84aa                	mv	s1,a0
    80004390:	0001e797          	auipc	a5,0x1e
    80004394:	d947a783          	lw	a5,-620(a5) # 80022124 <log+0x1c>
    80004398:	37fd                	addiw	a5,a5,-1
    8000439a:	06f75863          	bge	a4,a5,8000440a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000439e:	0001e797          	auipc	a5,0x1e
    800043a2:	d8a7a783          	lw	a5,-630(a5) # 80022128 <log+0x20>
    800043a6:	06f05a63          	blez	a5,8000441a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043aa:	0001e917          	auipc	s2,0x1e
    800043ae:	d5e90913          	addi	s2,s2,-674 # 80022108 <log>
    800043b2:	854a                	mv	a0,s2
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	8be080e7          	jalr	-1858(ra) # 80000c72 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	02c92603          	lw	a2,44(s2)
    800043c0:	06c05563          	blez	a2,8000442a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043c4:	44cc                	lw	a1,12(s1)
    800043c6:	0001e717          	auipc	a4,0x1e
    800043ca:	d7270713          	addi	a4,a4,-654 # 80022138 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ce:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043d0:	4314                	lw	a3,0(a4)
    800043d2:	04b68d63          	beq	a3,a1,8000442c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043d6:	2785                	addiw	a5,a5,1
    800043d8:	0711                	addi	a4,a4,4
    800043da:	fec79be3          	bne	a5,a2,800043d0 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043de:	0621                	addi	a2,a2,8
    800043e0:	060a                	slli	a2,a2,0x2
    800043e2:	0001e797          	auipc	a5,0x1e
    800043e6:	d2678793          	addi	a5,a5,-730 # 80022108 <log>
    800043ea:	963e                	add	a2,a2,a5
    800043ec:	44dc                	lw	a5,12(s1)
    800043ee:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043f0:	8526                	mv	a0,s1
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	dbc080e7          	jalr	-580(ra) # 800031ae <bpin>
    log.lh.n++;
    800043fa:	0001e717          	auipc	a4,0x1e
    800043fe:	d0e70713          	addi	a4,a4,-754 # 80022108 <log>
    80004402:	575c                	lw	a5,44(a4)
    80004404:	2785                	addiw	a5,a5,1
    80004406:	d75c                	sw	a5,44(a4)
    80004408:	a83d                	j	80004446 <log_write+0xd2>
    panic("too big a transaction");
    8000440a:	00004517          	auipc	a0,0x4
    8000440e:	23650513          	addi	a0,a0,566 # 80008640 <syscalls+0x200>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	1ce080e7          	jalr	462(ra) # 800005e0 <panic>
    panic("log_write outside of trans");
    8000441a:	00004517          	auipc	a0,0x4
    8000441e:	23e50513          	addi	a0,a0,574 # 80008658 <syscalls+0x218>
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	1be080e7          	jalr	446(ra) # 800005e0 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000442a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000442c:	00878713          	addi	a4,a5,8
    80004430:	00271693          	slli	a3,a4,0x2
    80004434:	0001e717          	auipc	a4,0x1e
    80004438:	cd470713          	addi	a4,a4,-812 # 80022108 <log>
    8000443c:	9736                	add	a4,a4,a3
    8000443e:	44d4                	lw	a3,12(s1)
    80004440:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004442:	faf607e3          	beq	a2,a5,800043f0 <log_write+0x7c>
  }
  release(&log.lock);
    80004446:	0001e517          	auipc	a0,0x1e
    8000444a:	cc250513          	addi	a0,a0,-830 # 80022108 <log>
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	8d8080e7          	jalr	-1832(ra) # 80000d26 <release>
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	e426                	sd	s1,8(sp)
    8000446a:	e04a                	sd	s2,0(sp)
    8000446c:	1000                	addi	s0,sp,32
    8000446e:	84aa                	mv	s1,a0
    80004470:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004472:	00004597          	auipc	a1,0x4
    80004476:	20658593          	addi	a1,a1,518 # 80008678 <syscalls+0x238>
    8000447a:	0521                	addi	a0,a0,8
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	766080e7          	jalr	1894(ra) # 80000be2 <initlock>
  lk->name = name;
    80004484:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004488:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000448c:	0204a423          	sw	zero,40(s1)
}
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6902                	ld	s2,0(sp)
    80004498:	6105                	addi	sp,sp,32
    8000449a:	8082                	ret

000000008000449c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000449c:	1101                	addi	sp,sp,-32
    8000449e:	ec06                	sd	ra,24(sp)
    800044a0:	e822                	sd	s0,16(sp)
    800044a2:	e426                	sd	s1,8(sp)
    800044a4:	e04a                	sd	s2,0(sp)
    800044a6:	1000                	addi	s0,sp,32
    800044a8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044aa:	00850913          	addi	s2,a0,8
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7c2080e7          	jalr	1986(ra) # 80000c72 <acquire>
  while (lk->locked) {
    800044b8:	409c                	lw	a5,0(s1)
    800044ba:	cb89                	beqz	a5,800044cc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044bc:	85ca                	mv	a1,s2
    800044be:	8526                	mv	a0,s1
    800044c0:	ffffe097          	auipc	ra,0xffffe
    800044c4:	dca080e7          	jalr	-566(ra) # 8000228a <sleep>
  while (lk->locked) {
    800044c8:	409c                	lw	a5,0(s1)
    800044ca:	fbed                	bnez	a5,800044bc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044cc:	4785                	li	a5,1
    800044ce:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044d0:	ffffd097          	auipc	ra,0xffffd
    800044d4:	56e080e7          	jalr	1390(ra) # 80001a3e <myproc>
    800044d8:	5d1c                	lw	a5,56(a0)
    800044da:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044dc:	854a                	mv	a0,s2
    800044de:	ffffd097          	auipc	ra,0xffffd
    800044e2:	848080e7          	jalr	-1976(ra) # 80000d26 <release>
}
    800044e6:	60e2                	ld	ra,24(sp)
    800044e8:	6442                	ld	s0,16(sp)
    800044ea:	64a2                	ld	s1,8(sp)
    800044ec:	6902                	ld	s2,0(sp)
    800044ee:	6105                	addi	sp,sp,32
    800044f0:	8082                	ret

00000000800044f2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044f2:	1101                	addi	sp,sp,-32
    800044f4:	ec06                	sd	ra,24(sp)
    800044f6:	e822                	sd	s0,16(sp)
    800044f8:	e426                	sd	s1,8(sp)
    800044fa:	e04a                	sd	s2,0(sp)
    800044fc:	1000                	addi	s0,sp,32
    800044fe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004500:	00850913          	addi	s2,a0,8
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	76c080e7          	jalr	1900(ra) # 80000c72 <acquire>
  lk->locked = 0;
    8000450e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004512:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004516:	8526                	mv	a0,s1
    80004518:	ffffe097          	auipc	ra,0xffffe
    8000451c:	ef2080e7          	jalr	-270(ra) # 8000240a <wakeup>
  release(&lk->lk);
    80004520:	854a                	mv	a0,s2
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	804080e7          	jalr	-2044(ra) # 80000d26 <release>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6902                	ld	s2,0(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004536:	7179                	addi	sp,sp,-48
    80004538:	f406                	sd	ra,40(sp)
    8000453a:	f022                	sd	s0,32(sp)
    8000453c:	ec26                	sd	s1,24(sp)
    8000453e:	e84a                	sd	s2,16(sp)
    80004540:	e44e                	sd	s3,8(sp)
    80004542:	1800                	addi	s0,sp,48
    80004544:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004546:	00850913          	addi	s2,a0,8
    8000454a:	854a                	mv	a0,s2
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	726080e7          	jalr	1830(ra) # 80000c72 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004554:	409c                	lw	a5,0(s1)
    80004556:	ef99                	bnez	a5,80004574 <holdingsleep+0x3e>
    80004558:	4481                	li	s1,0
  release(&lk->lk);
    8000455a:	854a                	mv	a0,s2
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	7ca080e7          	jalr	1994(ra) # 80000d26 <release>
  return r;
}
    80004564:	8526                	mv	a0,s1
    80004566:	70a2                	ld	ra,40(sp)
    80004568:	7402                	ld	s0,32(sp)
    8000456a:	64e2                	ld	s1,24(sp)
    8000456c:	6942                	ld	s2,16(sp)
    8000456e:	69a2                	ld	s3,8(sp)
    80004570:	6145                	addi	sp,sp,48
    80004572:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004574:	0284a983          	lw	s3,40(s1)
    80004578:	ffffd097          	auipc	ra,0xffffd
    8000457c:	4c6080e7          	jalr	1222(ra) # 80001a3e <myproc>
    80004580:	5d04                	lw	s1,56(a0)
    80004582:	413484b3          	sub	s1,s1,s3
    80004586:	0014b493          	seqz	s1,s1
    8000458a:	bfc1                	j	8000455a <holdingsleep+0x24>

000000008000458c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000458c:	1141                	addi	sp,sp,-16
    8000458e:	e406                	sd	ra,8(sp)
    80004590:	e022                	sd	s0,0(sp)
    80004592:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004594:	00004597          	auipc	a1,0x4
    80004598:	0f458593          	addi	a1,a1,244 # 80008688 <syscalls+0x248>
    8000459c:	0001e517          	auipc	a0,0x1e
    800045a0:	cb450513          	addi	a0,a0,-844 # 80022250 <ftable>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	63e080e7          	jalr	1598(ra) # 80000be2 <initlock>
}
    800045ac:	60a2                	ld	ra,8(sp)
    800045ae:	6402                	ld	s0,0(sp)
    800045b0:	0141                	addi	sp,sp,16
    800045b2:	8082                	ret

00000000800045b4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045b4:	1101                	addi	sp,sp,-32
    800045b6:	ec06                	sd	ra,24(sp)
    800045b8:	e822                	sd	s0,16(sp)
    800045ba:	e426                	sd	s1,8(sp)
    800045bc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045be:	0001e517          	auipc	a0,0x1e
    800045c2:	c9250513          	addi	a0,a0,-878 # 80022250 <ftable>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	6ac080e7          	jalr	1708(ra) # 80000c72 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ce:	0001e497          	auipc	s1,0x1e
    800045d2:	c9a48493          	addi	s1,s1,-870 # 80022268 <ftable+0x18>
    800045d6:	0001f717          	auipc	a4,0x1f
    800045da:	c3270713          	addi	a4,a4,-974 # 80023208 <ftable+0xfb8>
    if(f->ref == 0){
    800045de:	40dc                	lw	a5,4(s1)
    800045e0:	cf99                	beqz	a5,800045fe <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e2:	02848493          	addi	s1,s1,40
    800045e6:	fee49ce3          	bne	s1,a4,800045de <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ea:	0001e517          	auipc	a0,0x1e
    800045ee:	c6650513          	addi	a0,a0,-922 # 80022250 <ftable>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	734080e7          	jalr	1844(ra) # 80000d26 <release>
  return 0;
    800045fa:	4481                	li	s1,0
    800045fc:	a819                	j	80004612 <filealloc+0x5e>
      f->ref = 1;
    800045fe:	4785                	li	a5,1
    80004600:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004602:	0001e517          	auipc	a0,0x1e
    80004606:	c4e50513          	addi	a0,a0,-946 # 80022250 <ftable>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	71c080e7          	jalr	1820(ra) # 80000d26 <release>
}
    80004612:	8526                	mv	a0,s1
    80004614:	60e2                	ld	ra,24(sp)
    80004616:	6442                	ld	s0,16(sp)
    80004618:	64a2                	ld	s1,8(sp)
    8000461a:	6105                	addi	sp,sp,32
    8000461c:	8082                	ret

000000008000461e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000461e:	1101                	addi	sp,sp,-32
    80004620:	ec06                	sd	ra,24(sp)
    80004622:	e822                	sd	s0,16(sp)
    80004624:	e426                	sd	s1,8(sp)
    80004626:	1000                	addi	s0,sp,32
    80004628:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000462a:	0001e517          	auipc	a0,0x1e
    8000462e:	c2650513          	addi	a0,a0,-986 # 80022250 <ftable>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	640080e7          	jalr	1600(ra) # 80000c72 <acquire>
  if(f->ref < 1)
    8000463a:	40dc                	lw	a5,4(s1)
    8000463c:	02f05263          	blez	a5,80004660 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004640:	2785                	addiw	a5,a5,1
    80004642:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004644:	0001e517          	auipc	a0,0x1e
    80004648:	c0c50513          	addi	a0,a0,-1012 # 80022250 <ftable>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	6da080e7          	jalr	1754(ra) # 80000d26 <release>
  return f;
}
    80004654:	8526                	mv	a0,s1
    80004656:	60e2                	ld	ra,24(sp)
    80004658:	6442                	ld	s0,16(sp)
    8000465a:	64a2                	ld	s1,8(sp)
    8000465c:	6105                	addi	sp,sp,32
    8000465e:	8082                	ret
    panic("filedup");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	03050513          	addi	a0,a0,48 # 80008690 <syscalls+0x250>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	f78080e7          	jalr	-136(ra) # 800005e0 <panic>

0000000080004670 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004670:	7139                	addi	sp,sp,-64
    80004672:	fc06                	sd	ra,56(sp)
    80004674:	f822                	sd	s0,48(sp)
    80004676:	f426                	sd	s1,40(sp)
    80004678:	f04a                	sd	s2,32(sp)
    8000467a:	ec4e                	sd	s3,24(sp)
    8000467c:	e852                	sd	s4,16(sp)
    8000467e:	e456                	sd	s5,8(sp)
    80004680:	0080                	addi	s0,sp,64
    80004682:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004684:	0001e517          	auipc	a0,0x1e
    80004688:	bcc50513          	addi	a0,a0,-1076 # 80022250 <ftable>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	5e6080e7          	jalr	1510(ra) # 80000c72 <acquire>
  if(f->ref < 1)
    80004694:	40dc                	lw	a5,4(s1)
    80004696:	06f05163          	blez	a5,800046f8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000469a:	37fd                	addiw	a5,a5,-1
    8000469c:	0007871b          	sext.w	a4,a5
    800046a0:	c0dc                	sw	a5,4(s1)
    800046a2:	06e04363          	bgtz	a4,80004708 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046a6:	0004a903          	lw	s2,0(s1)
    800046aa:	0094ca83          	lbu	s5,9(s1)
    800046ae:	0104ba03          	ld	s4,16(s1)
    800046b2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046b6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046ba:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046be:	0001e517          	auipc	a0,0x1e
    800046c2:	b9250513          	addi	a0,a0,-1134 # 80022250 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	660080e7          	jalr	1632(ra) # 80000d26 <release>

  if(ff.type == FD_PIPE){
    800046ce:	4785                	li	a5,1
    800046d0:	04f90d63          	beq	s2,a5,8000472a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046d4:	3979                	addiw	s2,s2,-2
    800046d6:	4785                	li	a5,1
    800046d8:	0527e063          	bltu	a5,s2,80004718 <fileclose+0xa8>
    begin_op();
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	ac2080e7          	jalr	-1342(ra) # 8000419e <begin_op>
    iput(ff.ip);
    800046e4:	854e                	mv	a0,s3
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	2b6080e7          	jalr	694(ra) # 8000399c <iput>
    end_op();
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	b30080e7          	jalr	-1232(ra) # 8000421e <end_op>
    800046f6:	a00d                	j	80004718 <fileclose+0xa8>
    panic("fileclose");
    800046f8:	00004517          	auipc	a0,0x4
    800046fc:	fa050513          	addi	a0,a0,-96 # 80008698 <syscalls+0x258>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	ee0080e7          	jalr	-288(ra) # 800005e0 <panic>
    release(&ftable.lock);
    80004708:	0001e517          	auipc	a0,0x1e
    8000470c:	b4850513          	addi	a0,a0,-1208 # 80022250 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	616080e7          	jalr	1558(ra) # 80000d26 <release>
  }
}
    80004718:	70e2                	ld	ra,56(sp)
    8000471a:	7442                	ld	s0,48(sp)
    8000471c:	74a2                	ld	s1,40(sp)
    8000471e:	7902                	ld	s2,32(sp)
    80004720:	69e2                	ld	s3,24(sp)
    80004722:	6a42                	ld	s4,16(sp)
    80004724:	6aa2                	ld	s5,8(sp)
    80004726:	6121                	addi	sp,sp,64
    80004728:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000472a:	85d6                	mv	a1,s5
    8000472c:	8552                	mv	a0,s4
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	372080e7          	jalr	882(ra) # 80004aa0 <pipeclose>
    80004736:	b7cd                	j	80004718 <fileclose+0xa8>

0000000080004738 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004738:	715d                	addi	sp,sp,-80
    8000473a:	e486                	sd	ra,72(sp)
    8000473c:	e0a2                	sd	s0,64(sp)
    8000473e:	fc26                	sd	s1,56(sp)
    80004740:	f84a                	sd	s2,48(sp)
    80004742:	f44e                	sd	s3,40(sp)
    80004744:	0880                	addi	s0,sp,80
    80004746:	84aa                	mv	s1,a0
    80004748:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000474a:	ffffd097          	auipc	ra,0xffffd
    8000474e:	2f4080e7          	jalr	756(ra) # 80001a3e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004752:	409c                	lw	a5,0(s1)
    80004754:	37f9                	addiw	a5,a5,-2
    80004756:	4705                	li	a4,1
    80004758:	04f76763          	bltu	a4,a5,800047a6 <filestat+0x6e>
    8000475c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000475e:	6c88                	ld	a0,24(s1)
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	082080e7          	jalr	130(ra) # 800037e2 <ilock>
    stati(f->ip, &st);
    80004768:	fb840593          	addi	a1,s0,-72
    8000476c:	6c88                	ld	a0,24(s1)
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	2fe080e7          	jalr	766(ra) # 80003a6c <stati>
    iunlock(f->ip);
    80004776:	6c88                	ld	a0,24(s1)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	12c080e7          	jalr	300(ra) # 800038a4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004780:	46e1                	li	a3,24
    80004782:	fb840613          	addi	a2,s0,-72
    80004786:	85ce                	mv	a1,s3
    80004788:	05093503          	ld	a0,80(s2)
    8000478c:	ffffd097          	auipc	ra,0xffffd
    80004790:	fa4080e7          	jalr	-92(ra) # 80001730 <copyout>
    80004794:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004798:	60a6                	ld	ra,72(sp)
    8000479a:	6406                	ld	s0,64(sp)
    8000479c:	74e2                	ld	s1,56(sp)
    8000479e:	7942                	ld	s2,48(sp)
    800047a0:	79a2                	ld	s3,40(sp)
    800047a2:	6161                	addi	sp,sp,80
    800047a4:	8082                	ret
  return -1;
    800047a6:	557d                	li	a0,-1
    800047a8:	bfc5                	j	80004798 <filestat+0x60>

00000000800047aa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047aa:	7179                	addi	sp,sp,-48
    800047ac:	f406                	sd	ra,40(sp)
    800047ae:	f022                	sd	s0,32(sp)
    800047b0:	ec26                	sd	s1,24(sp)
    800047b2:	e84a                	sd	s2,16(sp)
    800047b4:	e44e                	sd	s3,8(sp)
    800047b6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047b8:	00854783          	lbu	a5,8(a0)
    800047bc:	c3d5                	beqz	a5,80004860 <fileread+0xb6>
    800047be:	84aa                	mv	s1,a0
    800047c0:	89ae                	mv	s3,a1
    800047c2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c4:	411c                	lw	a5,0(a0)
    800047c6:	4705                	li	a4,1
    800047c8:	04e78963          	beq	a5,a4,8000481a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047cc:	470d                	li	a4,3
    800047ce:	04e78d63          	beq	a5,a4,80004828 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d2:	4709                	li	a4,2
    800047d4:	06e79e63          	bne	a5,a4,80004850 <fileread+0xa6>
    ilock(f->ip);
    800047d8:	6d08                	ld	a0,24(a0)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	008080e7          	jalr	8(ra) # 800037e2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047e2:	874a                	mv	a4,s2
    800047e4:	5094                	lw	a3,32(s1)
    800047e6:	864e                	mv	a2,s3
    800047e8:	4585                	li	a1,1
    800047ea:	6c88                	ld	a0,24(s1)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	2aa080e7          	jalr	682(ra) # 80003a96 <readi>
    800047f4:	892a                	mv	s2,a0
    800047f6:	00a05563          	blez	a0,80004800 <fileread+0x56>
      f->off += r;
    800047fa:	509c                	lw	a5,32(s1)
    800047fc:	9fa9                	addw	a5,a5,a0
    800047fe:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004800:	6c88                	ld	a0,24(s1)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	0a2080e7          	jalr	162(ra) # 800038a4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000480a:	854a                	mv	a0,s2
    8000480c:	70a2                	ld	ra,40(sp)
    8000480e:	7402                	ld	s0,32(sp)
    80004810:	64e2                	ld	s1,24(sp)
    80004812:	6942                	ld	s2,16(sp)
    80004814:	69a2                	ld	s3,8(sp)
    80004816:	6145                	addi	sp,sp,48
    80004818:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000481a:	6908                	ld	a0,16(a0)
    8000481c:	00000097          	auipc	ra,0x0
    80004820:	3f4080e7          	jalr	1012(ra) # 80004c10 <piperead>
    80004824:	892a                	mv	s2,a0
    80004826:	b7d5                	j	8000480a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004828:	02451783          	lh	a5,36(a0)
    8000482c:	03079693          	slli	a3,a5,0x30
    80004830:	92c1                	srli	a3,a3,0x30
    80004832:	4725                	li	a4,9
    80004834:	02d76863          	bltu	a4,a3,80004864 <fileread+0xba>
    80004838:	0792                	slli	a5,a5,0x4
    8000483a:	0001e717          	auipc	a4,0x1e
    8000483e:	97670713          	addi	a4,a4,-1674 # 800221b0 <devsw>
    80004842:	97ba                	add	a5,a5,a4
    80004844:	639c                	ld	a5,0(a5)
    80004846:	c38d                	beqz	a5,80004868 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004848:	4505                	li	a0,1
    8000484a:	9782                	jalr	a5
    8000484c:	892a                	mv	s2,a0
    8000484e:	bf75                	j	8000480a <fileread+0x60>
    panic("fileread");
    80004850:	00004517          	auipc	a0,0x4
    80004854:	e5850513          	addi	a0,a0,-424 # 800086a8 <syscalls+0x268>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	d88080e7          	jalr	-632(ra) # 800005e0 <panic>
    return -1;
    80004860:	597d                	li	s2,-1
    80004862:	b765                	j	8000480a <fileread+0x60>
      return -1;
    80004864:	597d                	li	s2,-1
    80004866:	b755                	j	8000480a <fileread+0x60>
    80004868:	597d                	li	s2,-1
    8000486a:	b745                	j	8000480a <fileread+0x60>

000000008000486c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000486c:	00954783          	lbu	a5,9(a0)
    80004870:	14078563          	beqz	a5,800049ba <filewrite+0x14e>
{
    80004874:	715d                	addi	sp,sp,-80
    80004876:	e486                	sd	ra,72(sp)
    80004878:	e0a2                	sd	s0,64(sp)
    8000487a:	fc26                	sd	s1,56(sp)
    8000487c:	f84a                	sd	s2,48(sp)
    8000487e:	f44e                	sd	s3,40(sp)
    80004880:	f052                	sd	s4,32(sp)
    80004882:	ec56                	sd	s5,24(sp)
    80004884:	e85a                	sd	s6,16(sp)
    80004886:	e45e                	sd	s7,8(sp)
    80004888:	e062                	sd	s8,0(sp)
    8000488a:	0880                	addi	s0,sp,80
    8000488c:	892a                	mv	s2,a0
    8000488e:	8aae                	mv	s5,a1
    80004890:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004892:	411c                	lw	a5,0(a0)
    80004894:	4705                	li	a4,1
    80004896:	02e78263          	beq	a5,a4,800048ba <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000489a:	470d                	li	a4,3
    8000489c:	02e78563          	beq	a5,a4,800048c6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a0:	4709                	li	a4,2
    800048a2:	10e79463          	bne	a5,a4,800049aa <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048a6:	0ec05e63          	blez	a2,800049a2 <filewrite+0x136>
    int i = 0;
    800048aa:	4981                	li	s3,0
    800048ac:	6b05                	lui	s6,0x1
    800048ae:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048b2:	6b85                	lui	s7,0x1
    800048b4:	c00b8b9b          	addiw	s7,s7,-1024
    800048b8:	a851                	j	8000494c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048ba:	6908                	ld	a0,16(a0)
    800048bc:	00000097          	auipc	ra,0x0
    800048c0:	254080e7          	jalr	596(ra) # 80004b10 <pipewrite>
    800048c4:	a85d                	j	8000497a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048c6:	02451783          	lh	a5,36(a0)
    800048ca:	03079693          	slli	a3,a5,0x30
    800048ce:	92c1                	srli	a3,a3,0x30
    800048d0:	4725                	li	a4,9
    800048d2:	0ed76663          	bltu	a4,a3,800049be <filewrite+0x152>
    800048d6:	0792                	slli	a5,a5,0x4
    800048d8:	0001e717          	auipc	a4,0x1e
    800048dc:	8d870713          	addi	a4,a4,-1832 # 800221b0 <devsw>
    800048e0:	97ba                	add	a5,a5,a4
    800048e2:	679c                	ld	a5,8(a5)
    800048e4:	cff9                	beqz	a5,800049c2 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048e6:	4505                	li	a0,1
    800048e8:	9782                	jalr	a5
    800048ea:	a841                	j	8000497a <filewrite+0x10e>
    800048ec:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	8ae080e7          	jalr	-1874(ra) # 8000419e <begin_op>
      ilock(f->ip);
    800048f8:	01893503          	ld	a0,24(s2)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	ee6080e7          	jalr	-282(ra) # 800037e2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004904:	8762                	mv	a4,s8
    80004906:	02092683          	lw	a3,32(s2)
    8000490a:	01598633          	add	a2,s3,s5
    8000490e:	4585                	li	a1,1
    80004910:	01893503          	ld	a0,24(s2)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	278080e7          	jalr	632(ra) # 80003b8c <writei>
    8000491c:	84aa                	mv	s1,a0
    8000491e:	02a05f63          	blez	a0,8000495c <filewrite+0xf0>
        f->off += r;
    80004922:	02092783          	lw	a5,32(s2)
    80004926:	9fa9                	addw	a5,a5,a0
    80004928:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000492c:	01893503          	ld	a0,24(s2)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	f74080e7          	jalr	-140(ra) # 800038a4 <iunlock>
      end_op();
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	8e6080e7          	jalr	-1818(ra) # 8000421e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004940:	049c1963          	bne	s8,s1,80004992 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004944:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004948:	0349d663          	bge	s3,s4,80004974 <filewrite+0x108>
      int n1 = n - i;
    8000494c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004950:	84be                	mv	s1,a5
    80004952:	2781                	sext.w	a5,a5
    80004954:	f8fb5ce3          	bge	s6,a5,800048ec <filewrite+0x80>
    80004958:	84de                	mv	s1,s7
    8000495a:	bf49                	j	800048ec <filewrite+0x80>
      iunlock(f->ip);
    8000495c:	01893503          	ld	a0,24(s2)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	f44080e7          	jalr	-188(ra) # 800038a4 <iunlock>
      end_op();
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	8b6080e7          	jalr	-1866(ra) # 8000421e <end_op>
      if(r < 0)
    80004970:	fc04d8e3          	bgez	s1,80004940 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004974:	8552                	mv	a0,s4
    80004976:	033a1863          	bne	s4,s3,800049a6 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000497a:	60a6                	ld	ra,72(sp)
    8000497c:	6406                	ld	s0,64(sp)
    8000497e:	74e2                	ld	s1,56(sp)
    80004980:	7942                	ld	s2,48(sp)
    80004982:	79a2                	ld	s3,40(sp)
    80004984:	7a02                	ld	s4,32(sp)
    80004986:	6ae2                	ld	s5,24(sp)
    80004988:	6b42                	ld	s6,16(sp)
    8000498a:	6ba2                	ld	s7,8(sp)
    8000498c:	6c02                	ld	s8,0(sp)
    8000498e:	6161                	addi	sp,sp,80
    80004990:	8082                	ret
        panic("short filewrite");
    80004992:	00004517          	auipc	a0,0x4
    80004996:	d2650513          	addi	a0,a0,-730 # 800086b8 <syscalls+0x278>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	c46080e7          	jalr	-954(ra) # 800005e0 <panic>
    int i = 0;
    800049a2:	4981                	li	s3,0
    800049a4:	bfc1                	j	80004974 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049a6:	557d                	li	a0,-1
    800049a8:	bfc9                	j	8000497a <filewrite+0x10e>
    panic("filewrite");
    800049aa:	00004517          	auipc	a0,0x4
    800049ae:	d1e50513          	addi	a0,a0,-738 # 800086c8 <syscalls+0x288>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	c2e080e7          	jalr	-978(ra) # 800005e0 <panic>
    return -1;
    800049ba:	557d                	li	a0,-1
}
    800049bc:	8082                	ret
      return -1;
    800049be:	557d                	li	a0,-1
    800049c0:	bf6d                	j	8000497a <filewrite+0x10e>
    800049c2:	557d                	li	a0,-1
    800049c4:	bf5d                	j	8000497a <filewrite+0x10e>

00000000800049c6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049c6:	7179                	addi	sp,sp,-48
    800049c8:	f406                	sd	ra,40(sp)
    800049ca:	f022                	sd	s0,32(sp)
    800049cc:	ec26                	sd	s1,24(sp)
    800049ce:	e84a                	sd	s2,16(sp)
    800049d0:	e44e                	sd	s3,8(sp)
    800049d2:	e052                	sd	s4,0(sp)
    800049d4:	1800                	addi	s0,sp,48
    800049d6:	84aa                	mv	s1,a0
    800049d8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049da:	0005b023          	sd	zero,0(a1)
    800049de:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049e2:	00000097          	auipc	ra,0x0
    800049e6:	bd2080e7          	jalr	-1070(ra) # 800045b4 <filealloc>
    800049ea:	e088                	sd	a0,0(s1)
    800049ec:	c551                	beqz	a0,80004a78 <pipealloc+0xb2>
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	bc6080e7          	jalr	-1082(ra) # 800045b4 <filealloc>
    800049f6:	00aa3023          	sd	a0,0(s4)
    800049fa:	c92d                	beqz	a0,80004a6c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	186080e7          	jalr	390(ra) # 80000b82 <kalloc>
    80004a04:	892a                	mv	s2,a0
    80004a06:	c125                	beqz	a0,80004a66 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a08:	4985                	li	s3,1
    80004a0a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a0e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a12:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a16:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a1a:	00004597          	auipc	a1,0x4
    80004a1e:	cbe58593          	addi	a1,a1,-834 # 800086d8 <syscalls+0x298>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	1c0080e7          	jalr	448(ra) # 80000be2 <initlock>
  (*f0)->type = FD_PIPE;
    80004a2a:	609c                	ld	a5,0(s1)
    80004a2c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a30:	609c                	ld	a5,0(s1)
    80004a32:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a36:	609c                	ld	a5,0(s1)
    80004a38:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a3c:	609c                	ld	a5,0(s1)
    80004a3e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a42:	000a3783          	ld	a5,0(s4)
    80004a46:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a4a:	000a3783          	ld	a5,0(s4)
    80004a4e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a52:	000a3783          	ld	a5,0(s4)
    80004a56:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a5a:	000a3783          	ld	a5,0(s4)
    80004a5e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a62:	4501                	li	a0,0
    80004a64:	a025                	j	80004a8c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a66:	6088                	ld	a0,0(s1)
    80004a68:	e501                	bnez	a0,80004a70 <pipealloc+0xaa>
    80004a6a:	a039                	j	80004a78 <pipealloc+0xb2>
    80004a6c:	6088                	ld	a0,0(s1)
    80004a6e:	c51d                	beqz	a0,80004a9c <pipealloc+0xd6>
    fileclose(*f0);
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	c00080e7          	jalr	-1024(ra) # 80004670 <fileclose>
  if(*f1)
    80004a78:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a7c:	557d                	li	a0,-1
  if(*f1)
    80004a7e:	c799                	beqz	a5,80004a8c <pipealloc+0xc6>
    fileclose(*f1);
    80004a80:	853e                	mv	a0,a5
    80004a82:	00000097          	auipc	ra,0x0
    80004a86:	bee080e7          	jalr	-1042(ra) # 80004670 <fileclose>
  return -1;
    80004a8a:	557d                	li	a0,-1
}
    80004a8c:	70a2                	ld	ra,40(sp)
    80004a8e:	7402                	ld	s0,32(sp)
    80004a90:	64e2                	ld	s1,24(sp)
    80004a92:	6942                	ld	s2,16(sp)
    80004a94:	69a2                	ld	s3,8(sp)
    80004a96:	6a02                	ld	s4,0(sp)
    80004a98:	6145                	addi	sp,sp,48
    80004a9a:	8082                	ret
  return -1;
    80004a9c:	557d                	li	a0,-1
    80004a9e:	b7fd                	j	80004a8c <pipealloc+0xc6>

0000000080004aa0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aa0:	1101                	addi	sp,sp,-32
    80004aa2:	ec06                	sd	ra,24(sp)
    80004aa4:	e822                	sd	s0,16(sp)
    80004aa6:	e426                	sd	s1,8(sp)
    80004aa8:	e04a                	sd	s2,0(sp)
    80004aaa:	1000                	addi	s0,sp,32
    80004aac:	84aa                	mv	s1,a0
    80004aae:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1c2080e7          	jalr	450(ra) # 80000c72 <acquire>
  if(writable){
    80004ab8:	02090d63          	beqz	s2,80004af2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004abc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ac0:	21848513          	addi	a0,s1,536
    80004ac4:	ffffe097          	auipc	ra,0xffffe
    80004ac8:	946080e7          	jalr	-1722(ra) # 8000240a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004acc:	2204b783          	ld	a5,544(s1)
    80004ad0:	eb95                	bnez	a5,80004b04 <pipeclose+0x64>
    release(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	252080e7          	jalr	594(ra) # 80000d26 <release>
    kfree((char*)pi);
    80004adc:	8526                	mv	a0,s1
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	fa8080e7          	jalr	-88(ra) # 80000a86 <kfree>
  } else
    release(&pi->lock);
}
    80004ae6:	60e2                	ld	ra,24(sp)
    80004ae8:	6442                	ld	s0,16(sp)
    80004aea:	64a2                	ld	s1,8(sp)
    80004aec:	6902                	ld	s2,0(sp)
    80004aee:	6105                	addi	sp,sp,32
    80004af0:	8082                	ret
    pi->readopen = 0;
    80004af2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004af6:	21c48513          	addi	a0,s1,540
    80004afa:	ffffe097          	auipc	ra,0xffffe
    80004afe:	910080e7          	jalr	-1776(ra) # 8000240a <wakeup>
    80004b02:	b7e9                	j	80004acc <pipeclose+0x2c>
    release(&pi->lock);
    80004b04:	8526                	mv	a0,s1
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	220080e7          	jalr	544(ra) # 80000d26 <release>
}
    80004b0e:	bfe1                	j	80004ae6 <pipeclose+0x46>

0000000080004b10 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b10:	711d                	addi	sp,sp,-96
    80004b12:	ec86                	sd	ra,88(sp)
    80004b14:	e8a2                	sd	s0,80(sp)
    80004b16:	e4a6                	sd	s1,72(sp)
    80004b18:	e0ca                	sd	s2,64(sp)
    80004b1a:	fc4e                	sd	s3,56(sp)
    80004b1c:	f852                	sd	s4,48(sp)
    80004b1e:	f456                	sd	s5,40(sp)
    80004b20:	f05a                	sd	s6,32(sp)
    80004b22:	ec5e                	sd	s7,24(sp)
    80004b24:	e862                	sd	s8,16(sp)
    80004b26:	1080                	addi	s0,sp,96
    80004b28:	84aa                	mv	s1,a0
    80004b2a:	8b2e                	mv	s6,a1
    80004b2c:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	f10080e7          	jalr	-240(ra) # 80001a3e <myproc>
    80004b36:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	138080e7          	jalr	312(ra) # 80000c72 <acquire>
  for(i = 0; i < n; i++){
    80004b42:	09505763          	blez	s5,80004bd0 <pipewrite+0xc0>
    80004b46:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b48:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b4c:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b50:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b52:	2184a783          	lw	a5,536(s1)
    80004b56:	21c4a703          	lw	a4,540(s1)
    80004b5a:	2007879b          	addiw	a5,a5,512
    80004b5e:	02f71b63          	bne	a4,a5,80004b94 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004b62:	2204a783          	lw	a5,544(s1)
    80004b66:	c3d1                	beqz	a5,80004bea <pipewrite+0xda>
    80004b68:	03092783          	lw	a5,48(s2)
    80004b6c:	efbd                	bnez	a5,80004bea <pipewrite+0xda>
      wakeup(&pi->nread);
    80004b6e:	8552                	mv	a0,s4
    80004b70:	ffffe097          	auipc	ra,0xffffe
    80004b74:	89a080e7          	jalr	-1894(ra) # 8000240a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b78:	85a6                	mv	a1,s1
    80004b7a:	854e                	mv	a0,s3
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	70e080e7          	jalr	1806(ra) # 8000228a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b84:	2184a783          	lw	a5,536(s1)
    80004b88:	21c4a703          	lw	a4,540(s1)
    80004b8c:	2007879b          	addiw	a5,a5,512
    80004b90:	fcf709e3          	beq	a4,a5,80004b62 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b94:	4685                	li	a3,1
    80004b96:	865a                	mv	a2,s6
    80004b98:	faf40593          	addi	a1,s0,-81
    80004b9c:	05093503          	ld	a0,80(s2)
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	c1c080e7          	jalr	-996(ra) # 800017bc <copyin>
    80004ba8:	03850563          	beq	a0,s8,80004bd2 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bac:	21c4a783          	lw	a5,540(s1)
    80004bb0:	0017871b          	addiw	a4,a5,1
    80004bb4:	20e4ae23          	sw	a4,540(s1)
    80004bb8:	1ff7f793          	andi	a5,a5,511
    80004bbc:	97a6                	add	a5,a5,s1
    80004bbe:	faf44703          	lbu	a4,-81(s0)
    80004bc2:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bc6:	2b85                	addiw	s7,s7,1
    80004bc8:	0b05                	addi	s6,s6,1
    80004bca:	f97a94e3          	bne	s5,s7,80004b52 <pipewrite+0x42>
    80004bce:	a011                	j	80004bd2 <pipewrite+0xc2>
    80004bd0:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004bd2:	21848513          	addi	a0,s1,536
    80004bd6:	ffffe097          	auipc	ra,0xffffe
    80004bda:	834080e7          	jalr	-1996(ra) # 8000240a <wakeup>
  release(&pi->lock);
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	146080e7          	jalr	326(ra) # 80000d26 <release>
  return i;
    80004be8:	a039                	j	80004bf6 <pipewrite+0xe6>
        release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	13a080e7          	jalr	314(ra) # 80000d26 <release>
        return -1;
    80004bf4:	5bfd                	li	s7,-1
}
    80004bf6:	855e                	mv	a0,s7
    80004bf8:	60e6                	ld	ra,88(sp)
    80004bfa:	6446                	ld	s0,80(sp)
    80004bfc:	64a6                	ld	s1,72(sp)
    80004bfe:	6906                	ld	s2,64(sp)
    80004c00:	79e2                	ld	s3,56(sp)
    80004c02:	7a42                	ld	s4,48(sp)
    80004c04:	7aa2                	ld	s5,40(sp)
    80004c06:	7b02                	ld	s6,32(sp)
    80004c08:	6be2                	ld	s7,24(sp)
    80004c0a:	6c42                	ld	s8,16(sp)
    80004c0c:	6125                	addi	sp,sp,96
    80004c0e:	8082                	ret

0000000080004c10 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c10:	715d                	addi	sp,sp,-80
    80004c12:	e486                	sd	ra,72(sp)
    80004c14:	e0a2                	sd	s0,64(sp)
    80004c16:	fc26                	sd	s1,56(sp)
    80004c18:	f84a                	sd	s2,48(sp)
    80004c1a:	f44e                	sd	s3,40(sp)
    80004c1c:	f052                	sd	s4,32(sp)
    80004c1e:	ec56                	sd	s5,24(sp)
    80004c20:	e85a                	sd	s6,16(sp)
    80004c22:	0880                	addi	s0,sp,80
    80004c24:	84aa                	mv	s1,a0
    80004c26:	892e                	mv	s2,a1
    80004c28:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	e14080e7          	jalr	-492(ra) # 80001a3e <myproc>
    80004c32:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	03c080e7          	jalr	60(ra) # 80000c72 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3e:	2184a703          	lw	a4,536(s1)
    80004c42:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c46:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c4a:	02f71463          	bne	a4,a5,80004c72 <piperead+0x62>
    80004c4e:	2244a783          	lw	a5,548(s1)
    80004c52:	c385                	beqz	a5,80004c72 <piperead+0x62>
    if(pr->killed){
    80004c54:	030a2783          	lw	a5,48(s4)
    80004c58:	ebc1                	bnez	a5,80004ce8 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c5a:	85a6                	mv	a1,s1
    80004c5c:	854e                	mv	a0,s3
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	62c080e7          	jalr	1580(ra) # 8000228a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c66:	2184a703          	lw	a4,536(s1)
    80004c6a:	21c4a783          	lw	a5,540(s1)
    80004c6e:	fef700e3          	beq	a4,a5,80004c4e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c72:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c74:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c76:	05505363          	blez	s5,80004cbc <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c7a:	2184a783          	lw	a5,536(s1)
    80004c7e:	21c4a703          	lw	a4,540(s1)
    80004c82:	02f70d63          	beq	a4,a5,80004cbc <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c86:	0017871b          	addiw	a4,a5,1
    80004c8a:	20e4ac23          	sw	a4,536(s1)
    80004c8e:	1ff7f793          	andi	a5,a5,511
    80004c92:	97a6                	add	a5,a5,s1
    80004c94:	0187c783          	lbu	a5,24(a5)
    80004c98:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c9c:	4685                	li	a3,1
    80004c9e:	fbf40613          	addi	a2,s0,-65
    80004ca2:	85ca                	mv	a1,s2
    80004ca4:	050a3503          	ld	a0,80(s4)
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	a88080e7          	jalr	-1400(ra) # 80001730 <copyout>
    80004cb0:	01650663          	beq	a0,s6,80004cbc <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb4:	2985                	addiw	s3,s3,1
    80004cb6:	0905                	addi	s2,s2,1
    80004cb8:	fd3a91e3          	bne	s5,s3,80004c7a <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cbc:	21c48513          	addi	a0,s1,540
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	74a080e7          	jalr	1866(ra) # 8000240a <wakeup>
  release(&pi->lock);
    80004cc8:	8526                	mv	a0,s1
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	05c080e7          	jalr	92(ra) # 80000d26 <release>
  return i;
}
    80004cd2:	854e                	mv	a0,s3
    80004cd4:	60a6                	ld	ra,72(sp)
    80004cd6:	6406                	ld	s0,64(sp)
    80004cd8:	74e2                	ld	s1,56(sp)
    80004cda:	7942                	ld	s2,48(sp)
    80004cdc:	79a2                	ld	s3,40(sp)
    80004cde:	7a02                	ld	s4,32(sp)
    80004ce0:	6ae2                	ld	s5,24(sp)
    80004ce2:	6b42                	ld	s6,16(sp)
    80004ce4:	6161                	addi	sp,sp,80
    80004ce6:	8082                	ret
      release(&pi->lock);
    80004ce8:	8526                	mv	a0,s1
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	03c080e7          	jalr	60(ra) # 80000d26 <release>
      return -1;
    80004cf2:	59fd                	li	s3,-1
    80004cf4:	bff9                	j	80004cd2 <piperead+0xc2>

0000000080004cf6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cf6:	de010113          	addi	sp,sp,-544
    80004cfa:	20113c23          	sd	ra,536(sp)
    80004cfe:	20813823          	sd	s0,528(sp)
    80004d02:	20913423          	sd	s1,520(sp)
    80004d06:	21213023          	sd	s2,512(sp)
    80004d0a:	ffce                	sd	s3,504(sp)
    80004d0c:	fbd2                	sd	s4,496(sp)
    80004d0e:	f7d6                	sd	s5,488(sp)
    80004d10:	f3da                	sd	s6,480(sp)
    80004d12:	efde                	sd	s7,472(sp)
    80004d14:	ebe2                	sd	s8,464(sp)
    80004d16:	e7e6                	sd	s9,456(sp)
    80004d18:	e3ea                	sd	s10,448(sp)
    80004d1a:	ff6e                	sd	s11,440(sp)
    80004d1c:	1400                	addi	s0,sp,544
    80004d1e:	892a                	mv	s2,a0
    80004d20:	dea43423          	sd	a0,-536(s0)
    80004d24:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	d16080e7          	jalr	-746(ra) # 80001a3e <myproc>
    80004d30:	84aa                	mv	s1,a0

  begin_op();
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	46c080e7          	jalr	1132(ra) # 8000419e <begin_op>

  if((ip = namei(path)) == 0){
    80004d3a:	854a                	mv	a0,s2
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	256080e7          	jalr	598(ra) # 80003f92 <namei>
    80004d44:	c93d                	beqz	a0,80004dba <exec+0xc4>
    80004d46:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	a9a080e7          	jalr	-1382(ra) # 800037e2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d50:	04000713          	li	a4,64
    80004d54:	4681                	li	a3,0
    80004d56:	e4840613          	addi	a2,s0,-440
    80004d5a:	4581                	li	a1,0
    80004d5c:	8556                	mv	a0,s5
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	d38080e7          	jalr	-712(ra) # 80003a96 <readi>
    80004d66:	04000793          	li	a5,64
    80004d6a:	00f51a63          	bne	a0,a5,80004d7e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d6e:	e4842703          	lw	a4,-440(s0)
    80004d72:	464c47b7          	lui	a5,0x464c4
    80004d76:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d7a:	04f70663          	beq	a4,a5,80004dc6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d7e:	8556                	mv	a0,s5
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	cc4080e7          	jalr	-828(ra) # 80003a44 <iunlockput>
    end_op();
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	496080e7          	jalr	1174(ra) # 8000421e <end_op>
  }
  return -1;
    80004d90:	557d                	li	a0,-1
}
    80004d92:	21813083          	ld	ra,536(sp)
    80004d96:	21013403          	ld	s0,528(sp)
    80004d9a:	20813483          	ld	s1,520(sp)
    80004d9e:	20013903          	ld	s2,512(sp)
    80004da2:	79fe                	ld	s3,504(sp)
    80004da4:	7a5e                	ld	s4,496(sp)
    80004da6:	7abe                	ld	s5,488(sp)
    80004da8:	7b1e                	ld	s6,480(sp)
    80004daa:	6bfe                	ld	s7,472(sp)
    80004dac:	6c5e                	ld	s8,464(sp)
    80004dae:	6cbe                	ld	s9,456(sp)
    80004db0:	6d1e                	ld	s10,448(sp)
    80004db2:	7dfa                	ld	s11,440(sp)
    80004db4:	22010113          	addi	sp,sp,544
    80004db8:	8082                	ret
    end_op();
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	464080e7          	jalr	1124(ra) # 8000421e <end_op>
    return -1;
    80004dc2:	557d                	li	a0,-1
    80004dc4:	b7f9                	j	80004d92 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	d3a080e7          	jalr	-710(ra) # 80001b02 <proc_pagetable>
    80004dd0:	8b2a                	mv	s6,a0
    80004dd2:	d555                	beqz	a0,80004d7e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd4:	e6842783          	lw	a5,-408(s0)
    80004dd8:	e8045703          	lhu	a4,-384(s0)
    80004ddc:	c735                	beqz	a4,80004e48 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dde:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004de4:	6a05                	lui	s4,0x1
    80004de6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dea:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004dee:	6d85                	lui	s11,0x1
    80004df0:	7d7d                	lui	s10,0xfffff
    80004df2:	ac1d                	j	80005028 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004df4:	00004517          	auipc	a0,0x4
    80004df8:	8ec50513          	addi	a0,a0,-1812 # 800086e0 <syscalls+0x2a0>
    80004dfc:	ffffb097          	auipc	ra,0xffffb
    80004e00:	7e4080e7          	jalr	2020(ra) # 800005e0 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e04:	874a                	mv	a4,s2
    80004e06:	009c86bb          	addw	a3,s9,s1
    80004e0a:	4581                	li	a1,0
    80004e0c:	8556                	mv	a0,s5
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	c88080e7          	jalr	-888(ra) # 80003a96 <readi>
    80004e16:	2501                	sext.w	a0,a0
    80004e18:	1aa91863          	bne	s2,a0,80004fc8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e1c:	009d84bb          	addw	s1,s11,s1
    80004e20:	013d09bb          	addw	s3,s10,s3
    80004e24:	1f74f263          	bgeu	s1,s7,80005008 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e28:	02049593          	slli	a1,s1,0x20
    80004e2c:	9181                	srli	a1,a1,0x20
    80004e2e:	95e2                	add	a1,a1,s8
    80004e30:	855a                	mv	a0,s6
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	2ca080e7          	jalr	714(ra) # 800010fc <walkaddr>
    80004e3a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e3c:	dd45                	beqz	a0,80004df4 <exec+0xfe>
      n = PGSIZE;
    80004e3e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e40:	fd49f2e3          	bgeu	s3,s4,80004e04 <exec+0x10e>
      n = sz - i;
    80004e44:	894e                	mv	s2,s3
    80004e46:	bf7d                	j	80004e04 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e48:	4481                	li	s1,0
  iunlockput(ip);
    80004e4a:	8556                	mv	a0,s5
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	bf8080e7          	jalr	-1032(ra) # 80003a44 <iunlockput>
  end_op();
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	3ca080e7          	jalr	970(ra) # 8000421e <end_op>
  p = myproc();
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	be2080e7          	jalr	-1054(ra) # 80001a3e <myproc>
    80004e64:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e66:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e6a:	6785                	lui	a5,0x1
    80004e6c:	17fd                	addi	a5,a5,-1
    80004e6e:	94be                	add	s1,s1,a5
    80004e70:	77fd                	lui	a5,0xfffff
    80004e72:	8fe5                	and	a5,a5,s1
    80004e74:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e78:	6609                	lui	a2,0x2
    80004e7a:	963e                	add	a2,a2,a5
    80004e7c:	85be                	mv	a1,a5
    80004e7e:	855a                	mv	a0,s6
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	660080e7          	jalr	1632(ra) # 800014e0 <uvmalloc>
    80004e88:	8c2a                	mv	s8,a0
  ip = 0;
    80004e8a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e8c:	12050e63          	beqz	a0,80004fc8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e90:	75f9                	lui	a1,0xffffe
    80004e92:	95aa                	add	a1,a1,a0
    80004e94:	855a                	mv	a0,s6
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	868080e7          	jalr	-1944(ra) # 800016fe <uvmclear>
  stackbase = sp - PGSIZE;
    80004e9e:	7afd                	lui	s5,0xfffff
    80004ea0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ea2:	df043783          	ld	a5,-528(s0)
    80004ea6:	6388                	ld	a0,0(a5)
    80004ea8:	c925                	beqz	a0,80004f18 <exec+0x222>
    80004eaa:	e8840993          	addi	s3,s0,-376
    80004eae:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004eb2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eb4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	03c080e7          	jalr	60(ra) # 80000ef2 <strlen>
    80004ebe:	0015079b          	addiw	a5,a0,1
    80004ec2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ec6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eca:	13596363          	bltu	s2,s5,80004ff0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ece:	df043d83          	ld	s11,-528(s0)
    80004ed2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ed6:	8552                	mv	a0,s4
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	01a080e7          	jalr	26(ra) # 80000ef2 <strlen>
    80004ee0:	0015069b          	addiw	a3,a0,1
    80004ee4:	8652                	mv	a2,s4
    80004ee6:	85ca                	mv	a1,s2
    80004ee8:	855a                	mv	a0,s6
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	846080e7          	jalr	-1978(ra) # 80001730 <copyout>
    80004ef2:	10054363          	bltz	a0,80004ff8 <exec+0x302>
    ustack[argc] = sp;
    80004ef6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004efa:	0485                	addi	s1,s1,1
    80004efc:	008d8793          	addi	a5,s11,8
    80004f00:	def43823          	sd	a5,-528(s0)
    80004f04:	008db503          	ld	a0,8(s11)
    80004f08:	c911                	beqz	a0,80004f1c <exec+0x226>
    if(argc >= MAXARG)
    80004f0a:	09a1                	addi	s3,s3,8
    80004f0c:	fb3c95e3          	bne	s9,s3,80004eb6 <exec+0x1c0>
  sz = sz1;
    80004f10:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f14:	4a81                	li	s5,0
    80004f16:	a84d                	j	80004fc8 <exec+0x2d2>
  sp = sz;
    80004f18:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f1a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f1c:	00349793          	slli	a5,s1,0x3
    80004f20:	f9040713          	addi	a4,s0,-112
    80004f24:	97ba                	add	a5,a5,a4
    80004f26:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f2a:	00148693          	addi	a3,s1,1
    80004f2e:	068e                	slli	a3,a3,0x3
    80004f30:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f34:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f38:	01597663          	bgeu	s2,s5,80004f44 <exec+0x24e>
  sz = sz1;
    80004f3c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f40:	4a81                	li	s5,0
    80004f42:	a059                	j	80004fc8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f44:	e8840613          	addi	a2,s0,-376
    80004f48:	85ca                	mv	a1,s2
    80004f4a:	855a                	mv	a0,s6
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	7e4080e7          	jalr	2020(ra) # 80001730 <copyout>
    80004f54:	0a054663          	bltz	a0,80005000 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f58:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f5c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f60:	de843783          	ld	a5,-536(s0)
    80004f64:	0007c703          	lbu	a4,0(a5)
    80004f68:	cf11                	beqz	a4,80004f84 <exec+0x28e>
    80004f6a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f6c:	02f00693          	li	a3,47
    80004f70:	a039                	j	80004f7e <exec+0x288>
      last = s+1;
    80004f72:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f76:	0785                	addi	a5,a5,1
    80004f78:	fff7c703          	lbu	a4,-1(a5)
    80004f7c:	c701                	beqz	a4,80004f84 <exec+0x28e>
    if(*s == '/')
    80004f7e:	fed71ce3          	bne	a4,a3,80004f76 <exec+0x280>
    80004f82:	bfc5                	j	80004f72 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f84:	4641                	li	a2,16
    80004f86:	de843583          	ld	a1,-536(s0)
    80004f8a:	168b8513          	addi	a0,s7,360
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	f32080e7          	jalr	-206(ra) # 80000ec0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f96:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f9a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f9e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fa2:	058bb783          	ld	a5,88(s7)
    80004fa6:	e6043703          	ld	a4,-416(s0)
    80004faa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fac:	058bb783          	ld	a5,88(s7)
    80004fb0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fb4:	85ea                	mv	a1,s10
    80004fb6:	ffffd097          	auipc	ra,0xffffd
    80004fba:	be8080e7          	jalr	-1048(ra) # 80001b9e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fbe:	0004851b          	sext.w	a0,s1
    80004fc2:	bbc1                	j	80004d92 <exec+0x9c>
    80004fc4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fc8:	df843583          	ld	a1,-520(s0)
    80004fcc:	855a                	mv	a0,s6
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	bd0080e7          	jalr	-1072(ra) # 80001b9e <proc_freepagetable>
  if(ip){
    80004fd6:	da0a94e3          	bnez	s5,80004d7e <exec+0x88>
  return -1;
    80004fda:	557d                	li	a0,-1
    80004fdc:	bb5d                	j	80004d92 <exec+0x9c>
    80004fde:	de943c23          	sd	s1,-520(s0)
    80004fe2:	b7dd                	j	80004fc8 <exec+0x2d2>
    80004fe4:	de943c23          	sd	s1,-520(s0)
    80004fe8:	b7c5                	j	80004fc8 <exec+0x2d2>
    80004fea:	de943c23          	sd	s1,-520(s0)
    80004fee:	bfe9                	j	80004fc8 <exec+0x2d2>
  sz = sz1;
    80004ff0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ff4:	4a81                	li	s5,0
    80004ff6:	bfc9                	j	80004fc8 <exec+0x2d2>
  sz = sz1;
    80004ff8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ffc:	4a81                	li	s5,0
    80004ffe:	b7e9                	j	80004fc8 <exec+0x2d2>
  sz = sz1;
    80005000:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005004:	4a81                	li	s5,0
    80005006:	b7c9                	j	80004fc8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005008:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000500c:	e0843783          	ld	a5,-504(s0)
    80005010:	0017869b          	addiw	a3,a5,1
    80005014:	e0d43423          	sd	a3,-504(s0)
    80005018:	e0043783          	ld	a5,-512(s0)
    8000501c:	0387879b          	addiw	a5,a5,56
    80005020:	e8045703          	lhu	a4,-384(s0)
    80005024:	e2e6d3e3          	bge	a3,a4,80004e4a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005028:	2781                	sext.w	a5,a5
    8000502a:	e0f43023          	sd	a5,-512(s0)
    8000502e:	03800713          	li	a4,56
    80005032:	86be                	mv	a3,a5
    80005034:	e1040613          	addi	a2,s0,-496
    80005038:	4581                	li	a1,0
    8000503a:	8556                	mv	a0,s5
    8000503c:	fffff097          	auipc	ra,0xfffff
    80005040:	a5a080e7          	jalr	-1446(ra) # 80003a96 <readi>
    80005044:	03800793          	li	a5,56
    80005048:	f6f51ee3          	bne	a0,a5,80004fc4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000504c:	e1042783          	lw	a5,-496(s0)
    80005050:	4705                	li	a4,1
    80005052:	fae79de3          	bne	a5,a4,8000500c <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005056:	e3843603          	ld	a2,-456(s0)
    8000505a:	e3043783          	ld	a5,-464(s0)
    8000505e:	f8f660e3          	bltu	a2,a5,80004fde <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005062:	e2043783          	ld	a5,-480(s0)
    80005066:	963e                	add	a2,a2,a5
    80005068:	f6f66ee3          	bltu	a2,a5,80004fe4 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000506c:	85a6                	mv	a1,s1
    8000506e:	855a                	mv	a0,s6
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	470080e7          	jalr	1136(ra) # 800014e0 <uvmalloc>
    80005078:	dea43c23          	sd	a0,-520(s0)
    8000507c:	d53d                	beqz	a0,80004fea <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000507e:	e2043c03          	ld	s8,-480(s0)
    80005082:	de043783          	ld	a5,-544(s0)
    80005086:	00fc77b3          	and	a5,s8,a5
    8000508a:	ff9d                	bnez	a5,80004fc8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000508c:	e1842c83          	lw	s9,-488(s0)
    80005090:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005094:	f60b8ae3          	beqz	s7,80005008 <exec+0x312>
    80005098:	89de                	mv	s3,s7
    8000509a:	4481                	li	s1,0
    8000509c:	b371                	j	80004e28 <exec+0x132>

000000008000509e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000509e:	7179                	addi	sp,sp,-48
    800050a0:	f406                	sd	ra,40(sp)
    800050a2:	f022                	sd	s0,32(sp)
    800050a4:	ec26                	sd	s1,24(sp)
    800050a6:	e84a                	sd	s2,16(sp)
    800050a8:	1800                	addi	s0,sp,48
    800050aa:	892e                	mv	s2,a1
    800050ac:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050ae:	fdc40593          	addi	a1,s0,-36
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	b54080e7          	jalr	-1196(ra) # 80002c06 <argint>
    800050ba:	04054063          	bltz	a0,800050fa <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050be:	fdc42703          	lw	a4,-36(s0)
    800050c2:	47bd                	li	a5,15
    800050c4:	02e7ed63          	bltu	a5,a4,800050fe <argfd+0x60>
    800050c8:	ffffd097          	auipc	ra,0xffffd
    800050cc:	976080e7          	jalr	-1674(ra) # 80001a3e <myproc>
    800050d0:	fdc42703          	lw	a4,-36(s0)
    800050d4:	01c70793          	addi	a5,a4,28
    800050d8:	078e                	slli	a5,a5,0x3
    800050da:	953e                	add	a0,a0,a5
    800050dc:	611c                	ld	a5,0(a0)
    800050de:	c395                	beqz	a5,80005102 <argfd+0x64>
    return -1;
  if(pfd)
    800050e0:	00090463          	beqz	s2,800050e8 <argfd+0x4a>
    *pfd = fd;
    800050e4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050e8:	4501                	li	a0,0
  if(pf)
    800050ea:	c091                	beqz	s1,800050ee <argfd+0x50>
    *pf = f;
    800050ec:	e09c                	sd	a5,0(s1)
}
    800050ee:	70a2                	ld	ra,40(sp)
    800050f0:	7402                	ld	s0,32(sp)
    800050f2:	64e2                	ld	s1,24(sp)
    800050f4:	6942                	ld	s2,16(sp)
    800050f6:	6145                	addi	sp,sp,48
    800050f8:	8082                	ret
    return -1;
    800050fa:	557d                	li	a0,-1
    800050fc:	bfcd                	j	800050ee <argfd+0x50>
    return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	b7fd                	j	800050ee <argfd+0x50>
    80005102:	557d                	li	a0,-1
    80005104:	b7ed                	j	800050ee <argfd+0x50>

0000000080005106 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005106:	1101                	addi	sp,sp,-32
    80005108:	ec06                	sd	ra,24(sp)
    8000510a:	e822                	sd	s0,16(sp)
    8000510c:	e426                	sd	s1,8(sp)
    8000510e:	1000                	addi	s0,sp,32
    80005110:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	92c080e7          	jalr	-1748(ra) # 80001a3e <myproc>
    8000511a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000511c:	0e050793          	addi	a5,a0,224
    80005120:	4501                	li	a0,0
    80005122:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005124:	6398                	ld	a4,0(a5)
    80005126:	cb19                	beqz	a4,8000513c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005128:	2505                	addiw	a0,a0,1
    8000512a:	07a1                	addi	a5,a5,8
    8000512c:	fed51ce3          	bne	a0,a3,80005124 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005130:	557d                	li	a0,-1
}
    80005132:	60e2                	ld	ra,24(sp)
    80005134:	6442                	ld	s0,16(sp)
    80005136:	64a2                	ld	s1,8(sp)
    80005138:	6105                	addi	sp,sp,32
    8000513a:	8082                	ret
      p->ofile[fd] = f;
    8000513c:	01c50793          	addi	a5,a0,28
    80005140:	078e                	slli	a5,a5,0x3
    80005142:	963e                	add	a2,a2,a5
    80005144:	e204                	sd	s1,0(a2)
      return fd;
    80005146:	b7f5                	j	80005132 <fdalloc+0x2c>

0000000080005148 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005148:	715d                	addi	sp,sp,-80
    8000514a:	e486                	sd	ra,72(sp)
    8000514c:	e0a2                	sd	s0,64(sp)
    8000514e:	fc26                	sd	s1,56(sp)
    80005150:	f84a                	sd	s2,48(sp)
    80005152:	f44e                	sd	s3,40(sp)
    80005154:	f052                	sd	s4,32(sp)
    80005156:	ec56                	sd	s5,24(sp)
    80005158:	0880                	addi	s0,sp,80
    8000515a:	89ae                	mv	s3,a1
    8000515c:	8ab2                	mv	s5,a2
    8000515e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005160:	fb040593          	addi	a1,s0,-80
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	e4c080e7          	jalr	-436(ra) # 80003fb0 <nameiparent>
    8000516c:	892a                	mv	s2,a0
    8000516e:	12050e63          	beqz	a0,800052aa <create+0x162>
    return 0;

  ilock(dp);
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	670080e7          	jalr	1648(ra) # 800037e2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000517a:	4601                	li	a2,0
    8000517c:	fb040593          	addi	a1,s0,-80
    80005180:	854a                	mv	a0,s2
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	b3e080e7          	jalr	-1218(ra) # 80003cc0 <dirlookup>
    8000518a:	84aa                	mv	s1,a0
    8000518c:	c921                	beqz	a0,800051dc <create+0x94>
    iunlockput(dp);
    8000518e:	854a                	mv	a0,s2
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	8b4080e7          	jalr	-1868(ra) # 80003a44 <iunlockput>
    ilock(ip);
    80005198:	8526                	mv	a0,s1
    8000519a:	ffffe097          	auipc	ra,0xffffe
    8000519e:	648080e7          	jalr	1608(ra) # 800037e2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051a2:	2981                	sext.w	s3,s3
    800051a4:	4789                	li	a5,2
    800051a6:	02f99463          	bne	s3,a5,800051ce <create+0x86>
    800051aa:	0444d783          	lhu	a5,68(s1)
    800051ae:	37f9                	addiw	a5,a5,-2
    800051b0:	17c2                	slli	a5,a5,0x30
    800051b2:	93c1                	srli	a5,a5,0x30
    800051b4:	4705                	li	a4,1
    800051b6:	00f76c63          	bltu	a4,a5,800051ce <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051ba:	8526                	mv	a0,s1
    800051bc:	60a6                	ld	ra,72(sp)
    800051be:	6406                	ld	s0,64(sp)
    800051c0:	74e2                	ld	s1,56(sp)
    800051c2:	7942                	ld	s2,48(sp)
    800051c4:	79a2                	ld	s3,40(sp)
    800051c6:	7a02                	ld	s4,32(sp)
    800051c8:	6ae2                	ld	s5,24(sp)
    800051ca:	6161                	addi	sp,sp,80
    800051cc:	8082                	ret
    iunlockput(ip);
    800051ce:	8526                	mv	a0,s1
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	874080e7          	jalr	-1932(ra) # 80003a44 <iunlockput>
    return 0;
    800051d8:	4481                	li	s1,0
    800051da:	b7c5                	j	800051ba <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051dc:	85ce                	mv	a1,s3
    800051de:	00092503          	lw	a0,0(s2)
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	468080e7          	jalr	1128(ra) # 8000364a <ialloc>
    800051ea:	84aa                	mv	s1,a0
    800051ec:	c521                	beqz	a0,80005234 <create+0xec>
  ilock(ip);
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	5f4080e7          	jalr	1524(ra) # 800037e2 <ilock>
  ip->major = major;
    800051f6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051fa:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051fe:	4a05                	li	s4,1
    80005200:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005204:	8526                	mv	a0,s1
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	512080e7          	jalr	1298(ra) # 80003718 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000520e:	2981                	sext.w	s3,s3
    80005210:	03498a63          	beq	s3,s4,80005244 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005214:	40d0                	lw	a2,4(s1)
    80005216:	fb040593          	addi	a1,s0,-80
    8000521a:	854a                	mv	a0,s2
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	cb4080e7          	jalr	-844(ra) # 80003ed0 <dirlink>
    80005224:	06054b63          	bltz	a0,8000529a <create+0x152>
  iunlockput(dp);
    80005228:	854a                	mv	a0,s2
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	81a080e7          	jalr	-2022(ra) # 80003a44 <iunlockput>
  return ip;
    80005232:	b761                	j	800051ba <create+0x72>
    panic("create: ialloc");
    80005234:	00003517          	auipc	a0,0x3
    80005238:	4cc50513          	addi	a0,a0,1228 # 80008700 <syscalls+0x2c0>
    8000523c:	ffffb097          	auipc	ra,0xffffb
    80005240:	3a4080e7          	jalr	932(ra) # 800005e0 <panic>
    dp->nlink++;  // for ".."
    80005244:	04a95783          	lhu	a5,74(s2)
    80005248:	2785                	addiw	a5,a5,1
    8000524a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000524e:	854a                	mv	a0,s2
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	4c8080e7          	jalr	1224(ra) # 80003718 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005258:	40d0                	lw	a2,4(s1)
    8000525a:	00003597          	auipc	a1,0x3
    8000525e:	4b658593          	addi	a1,a1,1206 # 80008710 <syscalls+0x2d0>
    80005262:	8526                	mv	a0,s1
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	c6c080e7          	jalr	-916(ra) # 80003ed0 <dirlink>
    8000526c:	00054f63          	bltz	a0,8000528a <create+0x142>
    80005270:	00492603          	lw	a2,4(s2)
    80005274:	00003597          	auipc	a1,0x3
    80005278:	4a458593          	addi	a1,a1,1188 # 80008718 <syscalls+0x2d8>
    8000527c:	8526                	mv	a0,s1
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	c52080e7          	jalr	-942(ra) # 80003ed0 <dirlink>
    80005286:	f80557e3          	bgez	a0,80005214 <create+0xcc>
      panic("create dots");
    8000528a:	00003517          	auipc	a0,0x3
    8000528e:	49650513          	addi	a0,a0,1174 # 80008720 <syscalls+0x2e0>
    80005292:	ffffb097          	auipc	ra,0xffffb
    80005296:	34e080e7          	jalr	846(ra) # 800005e0 <panic>
    panic("create: dirlink");
    8000529a:	00003517          	auipc	a0,0x3
    8000529e:	49650513          	addi	a0,a0,1174 # 80008730 <syscalls+0x2f0>
    800052a2:	ffffb097          	auipc	ra,0xffffb
    800052a6:	33e080e7          	jalr	830(ra) # 800005e0 <panic>
    return 0;
    800052aa:	84aa                	mv	s1,a0
    800052ac:	b739                	j	800051ba <create+0x72>

00000000800052ae <sys_dup>:
{
    800052ae:	7179                	addi	sp,sp,-48
    800052b0:	f406                	sd	ra,40(sp)
    800052b2:	f022                	sd	s0,32(sp)
    800052b4:	ec26                	sd	s1,24(sp)
    800052b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b8:	fd840613          	addi	a2,s0,-40
    800052bc:	4581                	li	a1,0
    800052be:	4501                	li	a0,0
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	dde080e7          	jalr	-546(ra) # 8000509e <argfd>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ca:	02054363          	bltz	a0,800052f0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052ce:	fd843503          	ld	a0,-40(s0)
    800052d2:	00000097          	auipc	ra,0x0
    800052d6:	e34080e7          	jalr	-460(ra) # 80005106 <fdalloc>
    800052da:	84aa                	mv	s1,a0
    return -1;
    800052dc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052de:	00054963          	bltz	a0,800052f0 <sys_dup+0x42>
  filedup(f);
    800052e2:	fd843503          	ld	a0,-40(s0)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	338080e7          	jalr	824(ra) # 8000461e <filedup>
  return fd;
    800052ee:	87a6                	mv	a5,s1
}
    800052f0:	853e                	mv	a0,a5
    800052f2:	70a2                	ld	ra,40(sp)
    800052f4:	7402                	ld	s0,32(sp)
    800052f6:	64e2                	ld	s1,24(sp)
    800052f8:	6145                	addi	sp,sp,48
    800052fa:	8082                	ret

00000000800052fc <sys_read>:
{
    800052fc:	7179                	addi	sp,sp,-48
    800052fe:	f406                	sd	ra,40(sp)
    80005300:	f022                	sd	s0,32(sp)
    80005302:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005304:	fe840613          	addi	a2,s0,-24
    80005308:	4581                	li	a1,0
    8000530a:	4501                	li	a0,0
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	d92080e7          	jalr	-622(ra) # 8000509e <argfd>
    return -1;
    80005314:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005316:	04054163          	bltz	a0,80005358 <sys_read+0x5c>
    8000531a:	fe440593          	addi	a1,s0,-28
    8000531e:	4509                	li	a0,2
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	8e6080e7          	jalr	-1818(ra) # 80002c06 <argint>
    return -1;
    80005328:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532a:	02054763          	bltz	a0,80005358 <sys_read+0x5c>
    8000532e:	fd840593          	addi	a1,s0,-40
    80005332:	4505                	li	a0,1
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	8f4080e7          	jalr	-1804(ra) # 80002c28 <argaddr>
    return -1;
    8000533c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533e:	00054d63          	bltz	a0,80005358 <sys_read+0x5c>
  return fileread(f, p, n);
    80005342:	fe442603          	lw	a2,-28(s0)
    80005346:	fd843583          	ld	a1,-40(s0)
    8000534a:	fe843503          	ld	a0,-24(s0)
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	45c080e7          	jalr	1116(ra) # 800047aa <fileread>
    80005356:	87aa                	mv	a5,a0
}
    80005358:	853e                	mv	a0,a5
    8000535a:	70a2                	ld	ra,40(sp)
    8000535c:	7402                	ld	s0,32(sp)
    8000535e:	6145                	addi	sp,sp,48
    80005360:	8082                	ret

0000000080005362 <sys_write>:
{
    80005362:	7179                	addi	sp,sp,-48
    80005364:	f406                	sd	ra,40(sp)
    80005366:	f022                	sd	s0,32(sp)
    80005368:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	fe840613          	addi	a2,s0,-24
    8000536e:	4581                	li	a1,0
    80005370:	4501                	li	a0,0
    80005372:	00000097          	auipc	ra,0x0
    80005376:	d2c080e7          	jalr	-724(ra) # 8000509e <argfd>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537c:	04054163          	bltz	a0,800053be <sys_write+0x5c>
    80005380:	fe440593          	addi	a1,s0,-28
    80005384:	4509                	li	a0,2
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	880080e7          	jalr	-1920(ra) # 80002c06 <argint>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	02054763          	bltz	a0,800053be <sys_write+0x5c>
    80005394:	fd840593          	addi	a1,s0,-40
    80005398:	4505                	li	a0,1
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	88e080e7          	jalr	-1906(ra) # 80002c28 <argaddr>
    return -1;
    800053a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a4:	00054d63          	bltz	a0,800053be <sys_write+0x5c>
  return filewrite(f, p, n);
    800053a8:	fe442603          	lw	a2,-28(s0)
    800053ac:	fd843583          	ld	a1,-40(s0)
    800053b0:	fe843503          	ld	a0,-24(s0)
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	4b8080e7          	jalr	1208(ra) # 8000486c <filewrite>
    800053bc:	87aa                	mv	a5,a0
}
    800053be:	853e                	mv	a0,a5
    800053c0:	70a2                	ld	ra,40(sp)
    800053c2:	7402                	ld	s0,32(sp)
    800053c4:	6145                	addi	sp,sp,48
    800053c6:	8082                	ret

00000000800053c8 <sys_close>:
{
    800053c8:	1101                	addi	sp,sp,-32
    800053ca:	ec06                	sd	ra,24(sp)
    800053cc:	e822                	sd	s0,16(sp)
    800053ce:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053d0:	fe040613          	addi	a2,s0,-32
    800053d4:	fec40593          	addi	a1,s0,-20
    800053d8:	4501                	li	a0,0
    800053da:	00000097          	auipc	ra,0x0
    800053de:	cc4080e7          	jalr	-828(ra) # 8000509e <argfd>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053e4:	02054463          	bltz	a0,8000540c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	656080e7          	jalr	1622(ra) # 80001a3e <myproc>
    800053f0:	fec42783          	lw	a5,-20(s0)
    800053f4:	07f1                	addi	a5,a5,28
    800053f6:	078e                	slli	a5,a5,0x3
    800053f8:	97aa                	add	a5,a5,a0
    800053fa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053fe:	fe043503          	ld	a0,-32(s0)
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	26e080e7          	jalr	622(ra) # 80004670 <fileclose>
  return 0;
    8000540a:	4781                	li	a5,0
}
    8000540c:	853e                	mv	a0,a5
    8000540e:	60e2                	ld	ra,24(sp)
    80005410:	6442                	ld	s0,16(sp)
    80005412:	6105                	addi	sp,sp,32
    80005414:	8082                	ret

0000000080005416 <sys_fstat>:
{
    80005416:	1101                	addi	sp,sp,-32
    80005418:	ec06                	sd	ra,24(sp)
    8000541a:	e822                	sd	s0,16(sp)
    8000541c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000541e:	fe840613          	addi	a2,s0,-24
    80005422:	4581                	li	a1,0
    80005424:	4501                	li	a0,0
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	c78080e7          	jalr	-904(ra) # 8000509e <argfd>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005430:	02054563          	bltz	a0,8000545a <sys_fstat+0x44>
    80005434:	fe040593          	addi	a1,s0,-32
    80005438:	4505                	li	a0,1
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	7ee080e7          	jalr	2030(ra) # 80002c28 <argaddr>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005444:	00054b63          	bltz	a0,8000545a <sys_fstat+0x44>
  return filestat(f, st);
    80005448:	fe043583          	ld	a1,-32(s0)
    8000544c:	fe843503          	ld	a0,-24(s0)
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	2e8080e7          	jalr	744(ra) # 80004738 <filestat>
    80005458:	87aa                	mv	a5,a0
}
    8000545a:	853e                	mv	a0,a5
    8000545c:	60e2                	ld	ra,24(sp)
    8000545e:	6442                	ld	s0,16(sp)
    80005460:	6105                	addi	sp,sp,32
    80005462:	8082                	ret

0000000080005464 <sys_link>:
{
    80005464:	7169                	addi	sp,sp,-304
    80005466:	f606                	sd	ra,296(sp)
    80005468:	f222                	sd	s0,288(sp)
    8000546a:	ee26                	sd	s1,280(sp)
    8000546c:	ea4a                	sd	s2,272(sp)
    8000546e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005470:	08000613          	li	a2,128
    80005474:	ed040593          	addi	a1,s0,-304
    80005478:	4501                	li	a0,0
    8000547a:	ffffd097          	auipc	ra,0xffffd
    8000547e:	7d0080e7          	jalr	2000(ra) # 80002c4a <argstr>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005484:	10054e63          	bltz	a0,800055a0 <sys_link+0x13c>
    80005488:	08000613          	li	a2,128
    8000548c:	f5040593          	addi	a1,s0,-176
    80005490:	4505                	li	a0,1
    80005492:	ffffd097          	auipc	ra,0xffffd
    80005496:	7b8080e7          	jalr	1976(ra) # 80002c4a <argstr>
    return -1;
    8000549a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549c:	10054263          	bltz	a0,800055a0 <sys_link+0x13c>
  begin_op();
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	cfe080e7          	jalr	-770(ra) # 8000419e <begin_op>
  if((ip = namei(old)) == 0){
    800054a8:	ed040513          	addi	a0,s0,-304
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	ae6080e7          	jalr	-1306(ra) # 80003f92 <namei>
    800054b4:	84aa                	mv	s1,a0
    800054b6:	c551                	beqz	a0,80005542 <sys_link+0xde>
  ilock(ip);
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	32a080e7          	jalr	810(ra) # 800037e2 <ilock>
  if(ip->type == T_DIR){
    800054c0:	04449703          	lh	a4,68(s1)
    800054c4:	4785                	li	a5,1
    800054c6:	08f70463          	beq	a4,a5,8000554e <sys_link+0xea>
  ip->nlink++;
    800054ca:	04a4d783          	lhu	a5,74(s1)
    800054ce:	2785                	addiw	a5,a5,1
    800054d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	242080e7          	jalr	578(ra) # 80003718 <iupdate>
  iunlock(ip);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	3c4080e7          	jalr	964(ra) # 800038a4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054e8:	fd040593          	addi	a1,s0,-48
    800054ec:	f5040513          	addi	a0,s0,-176
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	ac0080e7          	jalr	-1344(ra) # 80003fb0 <nameiparent>
    800054f8:	892a                	mv	s2,a0
    800054fa:	c935                	beqz	a0,8000556e <sys_link+0x10a>
  ilock(dp);
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	2e6080e7          	jalr	742(ra) # 800037e2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005504:	00092703          	lw	a4,0(s2)
    80005508:	409c                	lw	a5,0(s1)
    8000550a:	04f71d63          	bne	a4,a5,80005564 <sys_link+0x100>
    8000550e:	40d0                	lw	a2,4(s1)
    80005510:	fd040593          	addi	a1,s0,-48
    80005514:	854a                	mv	a0,s2
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	9ba080e7          	jalr	-1606(ra) # 80003ed0 <dirlink>
    8000551e:	04054363          	bltz	a0,80005564 <sys_link+0x100>
  iunlockput(dp);
    80005522:	854a                	mv	a0,s2
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	520080e7          	jalr	1312(ra) # 80003a44 <iunlockput>
  iput(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	46e080e7          	jalr	1134(ra) # 8000399c <iput>
  end_op();
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	ce8080e7          	jalr	-792(ra) # 8000421e <end_op>
  return 0;
    8000553e:	4781                	li	a5,0
    80005540:	a085                	j	800055a0 <sys_link+0x13c>
    end_op();
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	cdc080e7          	jalr	-804(ra) # 8000421e <end_op>
    return -1;
    8000554a:	57fd                	li	a5,-1
    8000554c:	a891                	j	800055a0 <sys_link+0x13c>
    iunlockput(ip);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	4f4080e7          	jalr	1268(ra) # 80003a44 <iunlockput>
    end_op();
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	cc6080e7          	jalr	-826(ra) # 8000421e <end_op>
    return -1;
    80005560:	57fd                	li	a5,-1
    80005562:	a83d                	j	800055a0 <sys_link+0x13c>
    iunlockput(dp);
    80005564:	854a                	mv	a0,s2
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	4de080e7          	jalr	1246(ra) # 80003a44 <iunlockput>
  ilock(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	272080e7          	jalr	626(ra) # 800037e2 <ilock>
  ip->nlink--;
    80005578:	04a4d783          	lhu	a5,74(s1)
    8000557c:	37fd                	addiw	a5,a5,-1
    8000557e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	194080e7          	jalr	404(ra) # 80003718 <iupdate>
  iunlockput(ip);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	4b6080e7          	jalr	1206(ra) # 80003a44 <iunlockput>
  end_op();
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	c88080e7          	jalr	-888(ra) # 8000421e <end_op>
  return -1;
    8000559e:	57fd                	li	a5,-1
}
    800055a0:	853e                	mv	a0,a5
    800055a2:	70b2                	ld	ra,296(sp)
    800055a4:	7412                	ld	s0,288(sp)
    800055a6:	64f2                	ld	s1,280(sp)
    800055a8:	6952                	ld	s2,272(sp)
    800055aa:	6155                	addi	sp,sp,304
    800055ac:	8082                	ret

00000000800055ae <sys_unlink>:
{
    800055ae:	7151                	addi	sp,sp,-240
    800055b0:	f586                	sd	ra,232(sp)
    800055b2:	f1a2                	sd	s0,224(sp)
    800055b4:	eda6                	sd	s1,216(sp)
    800055b6:	e9ca                	sd	s2,208(sp)
    800055b8:	e5ce                	sd	s3,200(sp)
    800055ba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055bc:	08000613          	li	a2,128
    800055c0:	f3040593          	addi	a1,s0,-208
    800055c4:	4501                	li	a0,0
    800055c6:	ffffd097          	auipc	ra,0xffffd
    800055ca:	684080e7          	jalr	1668(ra) # 80002c4a <argstr>
    800055ce:	18054163          	bltz	a0,80005750 <sys_unlink+0x1a2>
  begin_op();
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	bcc080e7          	jalr	-1076(ra) # 8000419e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055da:	fb040593          	addi	a1,s0,-80
    800055de:	f3040513          	addi	a0,s0,-208
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	9ce080e7          	jalr	-1586(ra) # 80003fb0 <nameiparent>
    800055ea:	84aa                	mv	s1,a0
    800055ec:	c979                	beqz	a0,800056c2 <sys_unlink+0x114>
  ilock(dp);
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	1f4080e7          	jalr	500(ra) # 800037e2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055f6:	00003597          	auipc	a1,0x3
    800055fa:	11a58593          	addi	a1,a1,282 # 80008710 <syscalls+0x2d0>
    800055fe:	fb040513          	addi	a0,s0,-80
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	6a4080e7          	jalr	1700(ra) # 80003ca6 <namecmp>
    8000560a:	14050a63          	beqz	a0,8000575e <sys_unlink+0x1b0>
    8000560e:	00003597          	auipc	a1,0x3
    80005612:	10a58593          	addi	a1,a1,266 # 80008718 <syscalls+0x2d8>
    80005616:	fb040513          	addi	a0,s0,-80
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	68c080e7          	jalr	1676(ra) # 80003ca6 <namecmp>
    80005622:	12050e63          	beqz	a0,8000575e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005626:	f2c40613          	addi	a2,s0,-212
    8000562a:	fb040593          	addi	a1,s0,-80
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	690080e7          	jalr	1680(ra) # 80003cc0 <dirlookup>
    80005638:	892a                	mv	s2,a0
    8000563a:	12050263          	beqz	a0,8000575e <sys_unlink+0x1b0>
  ilock(ip);
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	1a4080e7          	jalr	420(ra) # 800037e2 <ilock>
  if(ip->nlink < 1)
    80005646:	04a91783          	lh	a5,74(s2)
    8000564a:	08f05263          	blez	a5,800056ce <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000564e:	04491703          	lh	a4,68(s2)
    80005652:	4785                	li	a5,1
    80005654:	08f70563          	beq	a4,a5,800056de <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005658:	4641                	li	a2,16
    8000565a:	4581                	li	a1,0
    8000565c:	fc040513          	addi	a0,s0,-64
    80005660:	ffffb097          	auipc	ra,0xffffb
    80005664:	70e080e7          	jalr	1806(ra) # 80000d6e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005668:	4741                	li	a4,16
    8000566a:	f2c42683          	lw	a3,-212(s0)
    8000566e:	fc040613          	addi	a2,s0,-64
    80005672:	4581                	li	a1,0
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	516080e7          	jalr	1302(ra) # 80003b8c <writei>
    8000567e:	47c1                	li	a5,16
    80005680:	0af51563          	bne	a0,a5,8000572a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005684:	04491703          	lh	a4,68(s2)
    80005688:	4785                	li	a5,1
    8000568a:	0af70863          	beq	a4,a5,8000573a <sys_unlink+0x18c>
  iunlockput(dp);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	3b4080e7          	jalr	948(ra) # 80003a44 <iunlockput>
  ip->nlink--;
    80005698:	04a95783          	lhu	a5,74(s2)
    8000569c:	37fd                	addiw	a5,a5,-1
    8000569e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	074080e7          	jalr	116(ra) # 80003718 <iupdate>
  iunlockput(ip);
    800056ac:	854a                	mv	a0,s2
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	396080e7          	jalr	918(ra) # 80003a44 <iunlockput>
  end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	b68080e7          	jalr	-1176(ra) # 8000421e <end_op>
  return 0;
    800056be:	4501                	li	a0,0
    800056c0:	a84d                	j	80005772 <sys_unlink+0x1c4>
    end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	b5c080e7          	jalr	-1188(ra) # 8000421e <end_op>
    return -1;
    800056ca:	557d                	li	a0,-1
    800056cc:	a05d                	j	80005772 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056ce:	00003517          	auipc	a0,0x3
    800056d2:	07250513          	addi	a0,a0,114 # 80008740 <syscalls+0x300>
    800056d6:	ffffb097          	auipc	ra,0xffffb
    800056da:	f0a080e7          	jalr	-246(ra) # 800005e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056de:	04c92703          	lw	a4,76(s2)
    800056e2:	02000793          	li	a5,32
    800056e6:	f6e7f9e3          	bgeu	a5,a4,80005658 <sys_unlink+0xaa>
    800056ea:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ee:	4741                	li	a4,16
    800056f0:	86ce                	mv	a3,s3
    800056f2:	f1840613          	addi	a2,s0,-232
    800056f6:	4581                	li	a1,0
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	39c080e7          	jalr	924(ra) # 80003a96 <readi>
    80005702:	47c1                	li	a5,16
    80005704:	00f51b63          	bne	a0,a5,8000571a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005708:	f1845783          	lhu	a5,-232(s0)
    8000570c:	e7a1                	bnez	a5,80005754 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000570e:	29c1                	addiw	s3,s3,16
    80005710:	04c92783          	lw	a5,76(s2)
    80005714:	fcf9ede3          	bltu	s3,a5,800056ee <sys_unlink+0x140>
    80005718:	b781                	j	80005658 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000571a:	00003517          	auipc	a0,0x3
    8000571e:	03e50513          	addi	a0,a0,62 # 80008758 <syscalls+0x318>
    80005722:	ffffb097          	auipc	ra,0xffffb
    80005726:	ebe080e7          	jalr	-322(ra) # 800005e0 <panic>
    panic("unlink: writei");
    8000572a:	00003517          	auipc	a0,0x3
    8000572e:	04650513          	addi	a0,a0,70 # 80008770 <syscalls+0x330>
    80005732:	ffffb097          	auipc	ra,0xffffb
    80005736:	eae080e7          	jalr	-338(ra) # 800005e0 <panic>
    dp->nlink--;
    8000573a:	04a4d783          	lhu	a5,74(s1)
    8000573e:	37fd                	addiw	a5,a5,-1
    80005740:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005744:	8526                	mv	a0,s1
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	fd2080e7          	jalr	-46(ra) # 80003718 <iupdate>
    8000574e:	b781                	j	8000568e <sys_unlink+0xe0>
    return -1;
    80005750:	557d                	li	a0,-1
    80005752:	a005                	j	80005772 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005754:	854a                	mv	a0,s2
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	2ee080e7          	jalr	750(ra) # 80003a44 <iunlockput>
  iunlockput(dp);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	2e4080e7          	jalr	740(ra) # 80003a44 <iunlockput>
  end_op();
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	ab6080e7          	jalr	-1354(ra) # 8000421e <end_op>
  return -1;
    80005770:	557d                	li	a0,-1
}
    80005772:	70ae                	ld	ra,232(sp)
    80005774:	740e                	ld	s0,224(sp)
    80005776:	64ee                	ld	s1,216(sp)
    80005778:	694e                	ld	s2,208(sp)
    8000577a:	69ae                	ld	s3,200(sp)
    8000577c:	616d                	addi	sp,sp,240
    8000577e:	8082                	ret

0000000080005780 <sys_open>:

uint64
sys_open(void)
{
    80005780:	7131                	addi	sp,sp,-192
    80005782:	fd06                	sd	ra,184(sp)
    80005784:	f922                	sd	s0,176(sp)
    80005786:	f526                	sd	s1,168(sp)
    80005788:	f14a                	sd	s2,160(sp)
    8000578a:	ed4e                	sd	s3,152(sp)
    8000578c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000578e:	08000613          	li	a2,128
    80005792:	f5040593          	addi	a1,s0,-176
    80005796:	4501                	li	a0,0
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	4b2080e7          	jalr	1202(ra) # 80002c4a <argstr>
    return -1;
    800057a0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057a2:	0c054163          	bltz	a0,80005864 <sys_open+0xe4>
    800057a6:	f4c40593          	addi	a1,s0,-180
    800057aa:	4505                	li	a0,1
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	45a080e7          	jalr	1114(ra) # 80002c06 <argint>
    800057b4:	0a054863          	bltz	a0,80005864 <sys_open+0xe4>

  begin_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	9e6080e7          	jalr	-1562(ra) # 8000419e <begin_op>

  if(omode & O_CREATE){
    800057c0:	f4c42783          	lw	a5,-180(s0)
    800057c4:	2007f793          	andi	a5,a5,512
    800057c8:	cbdd                	beqz	a5,8000587e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057ca:	4681                	li	a3,0
    800057cc:	4601                	li	a2,0
    800057ce:	4589                	li	a1,2
    800057d0:	f5040513          	addi	a0,s0,-176
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	974080e7          	jalr	-1676(ra) # 80005148 <create>
    800057dc:	892a                	mv	s2,a0
    if(ip == 0){
    800057de:	c959                	beqz	a0,80005874 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057e0:	04491703          	lh	a4,68(s2)
    800057e4:	478d                	li	a5,3
    800057e6:	00f71763          	bne	a4,a5,800057f4 <sys_open+0x74>
    800057ea:	04695703          	lhu	a4,70(s2)
    800057ee:	47a5                	li	a5,9
    800057f0:	0ce7ec63          	bltu	a5,a4,800058c8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	dc0080e7          	jalr	-576(ra) # 800045b4 <filealloc>
    800057fc:	89aa                	mv	s3,a0
    800057fe:	10050263          	beqz	a0,80005902 <sys_open+0x182>
    80005802:	00000097          	auipc	ra,0x0
    80005806:	904080e7          	jalr	-1788(ra) # 80005106 <fdalloc>
    8000580a:	84aa                	mv	s1,a0
    8000580c:	0e054663          	bltz	a0,800058f8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005810:	04491703          	lh	a4,68(s2)
    80005814:	478d                	li	a5,3
    80005816:	0cf70463          	beq	a4,a5,800058de <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000581a:	4789                	li	a5,2
    8000581c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005820:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005824:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005828:	f4c42783          	lw	a5,-180(s0)
    8000582c:	0017c713          	xori	a4,a5,1
    80005830:	8b05                	andi	a4,a4,1
    80005832:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005836:	0037f713          	andi	a4,a5,3
    8000583a:	00e03733          	snez	a4,a4
    8000583e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005842:	4007f793          	andi	a5,a5,1024
    80005846:	c791                	beqz	a5,80005852 <sys_open+0xd2>
    80005848:	04491703          	lh	a4,68(s2)
    8000584c:	4789                	li	a5,2
    8000584e:	08f70f63          	beq	a4,a5,800058ec <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	050080e7          	jalr	80(ra) # 800038a4 <iunlock>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	9c2080e7          	jalr	-1598(ra) # 8000421e <end_op>

  return fd;
}
    80005864:	8526                	mv	a0,s1
    80005866:	70ea                	ld	ra,184(sp)
    80005868:	744a                	ld	s0,176(sp)
    8000586a:	74aa                	ld	s1,168(sp)
    8000586c:	790a                	ld	s2,160(sp)
    8000586e:	69ea                	ld	s3,152(sp)
    80005870:	6129                	addi	sp,sp,192
    80005872:	8082                	ret
      end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9aa080e7          	jalr	-1622(ra) # 8000421e <end_op>
      return -1;
    8000587c:	b7e5                	j	80005864 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000587e:	f5040513          	addi	a0,s0,-176
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	710080e7          	jalr	1808(ra) # 80003f92 <namei>
    8000588a:	892a                	mv	s2,a0
    8000588c:	c905                	beqz	a0,800058bc <sys_open+0x13c>
    ilock(ip);
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	f54080e7          	jalr	-172(ra) # 800037e2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005896:	04491703          	lh	a4,68(s2)
    8000589a:	4785                	li	a5,1
    8000589c:	f4f712e3          	bne	a4,a5,800057e0 <sys_open+0x60>
    800058a0:	f4c42783          	lw	a5,-180(s0)
    800058a4:	dba1                	beqz	a5,800057f4 <sys_open+0x74>
      iunlockput(ip);
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	19c080e7          	jalr	412(ra) # 80003a44 <iunlockput>
      end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	96e080e7          	jalr	-1682(ra) # 8000421e <end_op>
      return -1;
    800058b8:	54fd                	li	s1,-1
    800058ba:	b76d                	j	80005864 <sys_open+0xe4>
      end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	962080e7          	jalr	-1694(ra) # 8000421e <end_op>
      return -1;
    800058c4:	54fd                	li	s1,-1
    800058c6:	bf79                	j	80005864 <sys_open+0xe4>
    iunlockput(ip);
    800058c8:	854a                	mv	a0,s2
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	17a080e7          	jalr	378(ra) # 80003a44 <iunlockput>
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	94c080e7          	jalr	-1716(ra) # 8000421e <end_op>
    return -1;
    800058da:	54fd                	li	s1,-1
    800058dc:	b761                	j	80005864 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058de:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058e2:	04691783          	lh	a5,70(s2)
    800058e6:	02f99223          	sh	a5,36(s3)
    800058ea:	bf2d                	j	80005824 <sys_open+0xa4>
    itrunc(ip);
    800058ec:	854a                	mv	a0,s2
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	002080e7          	jalr	2(ra) # 800038f0 <itrunc>
    800058f6:	bfb1                	j	80005852 <sys_open+0xd2>
      fileclose(f);
    800058f8:	854e                	mv	a0,s3
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	d76080e7          	jalr	-650(ra) # 80004670 <fileclose>
    iunlockput(ip);
    80005902:	854a                	mv	a0,s2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	140080e7          	jalr	320(ra) # 80003a44 <iunlockput>
    end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	912080e7          	jalr	-1774(ra) # 8000421e <end_op>
    return -1;
    80005914:	54fd                	li	s1,-1
    80005916:	b7b9                	j	80005864 <sys_open+0xe4>

0000000080005918 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005918:	7175                	addi	sp,sp,-144
    8000591a:	e506                	sd	ra,136(sp)
    8000591c:	e122                	sd	s0,128(sp)
    8000591e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	87e080e7          	jalr	-1922(ra) # 8000419e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005928:	08000613          	li	a2,128
    8000592c:	f7040593          	addi	a1,s0,-144
    80005930:	4501                	li	a0,0
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	318080e7          	jalr	792(ra) # 80002c4a <argstr>
    8000593a:	02054963          	bltz	a0,8000596c <sys_mkdir+0x54>
    8000593e:	4681                	li	a3,0
    80005940:	4601                	li	a2,0
    80005942:	4585                	li	a1,1
    80005944:	f7040513          	addi	a0,s0,-144
    80005948:	00000097          	auipc	ra,0x0
    8000594c:	800080e7          	jalr	-2048(ra) # 80005148 <create>
    80005950:	cd11                	beqz	a0,8000596c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	0f2080e7          	jalr	242(ra) # 80003a44 <iunlockput>
  end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	8c4080e7          	jalr	-1852(ra) # 8000421e <end_op>
  return 0;
    80005962:	4501                	li	a0,0
}
    80005964:	60aa                	ld	ra,136(sp)
    80005966:	640a                	ld	s0,128(sp)
    80005968:	6149                	addi	sp,sp,144
    8000596a:	8082                	ret
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	8b2080e7          	jalr	-1870(ra) # 8000421e <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	b7fd                	j	80005964 <sys_mkdir+0x4c>

0000000080005978 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005978:	7135                	addi	sp,sp,-160
    8000597a:	ed06                	sd	ra,152(sp)
    8000597c:	e922                	sd	s0,144(sp)
    8000597e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	81e080e7          	jalr	-2018(ra) # 8000419e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005988:	08000613          	li	a2,128
    8000598c:	f7040593          	addi	a1,s0,-144
    80005990:	4501                	li	a0,0
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	2b8080e7          	jalr	696(ra) # 80002c4a <argstr>
    8000599a:	04054a63          	bltz	a0,800059ee <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000599e:	f6c40593          	addi	a1,s0,-148
    800059a2:	4505                	li	a0,1
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	262080e7          	jalr	610(ra) # 80002c06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ac:	04054163          	bltz	a0,800059ee <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059b0:	f6840593          	addi	a1,s0,-152
    800059b4:	4509                	li	a0,2
    800059b6:	ffffd097          	auipc	ra,0xffffd
    800059ba:	250080e7          	jalr	592(ra) # 80002c06 <argint>
     argint(1, &major) < 0 ||
    800059be:	02054863          	bltz	a0,800059ee <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059c2:	f6841683          	lh	a3,-152(s0)
    800059c6:	f6c41603          	lh	a2,-148(s0)
    800059ca:	458d                	li	a1,3
    800059cc:	f7040513          	addi	a0,s0,-144
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	778080e7          	jalr	1912(ra) # 80005148 <create>
     argint(2, &minor) < 0 ||
    800059d8:	c919                	beqz	a0,800059ee <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	06a080e7          	jalr	106(ra) # 80003a44 <iunlockput>
  end_op();
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	83c080e7          	jalr	-1988(ra) # 8000421e <end_op>
  return 0;
    800059ea:	4501                	li	a0,0
    800059ec:	a031                	j	800059f8 <sys_mknod+0x80>
    end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	830080e7          	jalr	-2000(ra) # 8000421e <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
}
    800059f8:	60ea                	ld	ra,152(sp)
    800059fa:	644a                	ld	s0,144(sp)
    800059fc:	610d                	addi	sp,sp,160
    800059fe:	8082                	ret

0000000080005a00 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a00:	7135                	addi	sp,sp,-160
    80005a02:	ed06                	sd	ra,152(sp)
    80005a04:	e922                	sd	s0,144(sp)
    80005a06:	e526                	sd	s1,136(sp)
    80005a08:	e14a                	sd	s2,128(sp)
    80005a0a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a0c:	ffffc097          	auipc	ra,0xffffc
    80005a10:	032080e7          	jalr	50(ra) # 80001a3e <myproc>
    80005a14:	892a                	mv	s2,a0
  
  begin_op();
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	788080e7          	jalr	1928(ra) # 8000419e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a1e:	08000613          	li	a2,128
    80005a22:	f6040593          	addi	a1,s0,-160
    80005a26:	4501                	li	a0,0
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	222080e7          	jalr	546(ra) # 80002c4a <argstr>
    80005a30:	04054b63          	bltz	a0,80005a86 <sys_chdir+0x86>
    80005a34:	f6040513          	addi	a0,s0,-160
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	55a080e7          	jalr	1370(ra) # 80003f92 <namei>
    80005a40:	84aa                	mv	s1,a0
    80005a42:	c131                	beqz	a0,80005a86 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	d9e080e7          	jalr	-610(ra) # 800037e2 <ilock>
  if(ip->type != T_DIR){
    80005a4c:	04449703          	lh	a4,68(s1)
    80005a50:	4785                	li	a5,1
    80005a52:	04f71063          	bne	a4,a5,80005a92 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	e4c080e7          	jalr	-436(ra) # 800038a4 <iunlock>
  iput(p->cwd);
    80005a60:	16093503          	ld	a0,352(s2)
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	f38080e7          	jalr	-200(ra) # 8000399c <iput>
  end_op();
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	7b2080e7          	jalr	1970(ra) # 8000421e <end_op>
  p->cwd = ip;
    80005a74:	16993023          	sd	s1,352(s2)
  return 0;
    80005a78:	4501                	li	a0,0
}
    80005a7a:	60ea                	ld	ra,152(sp)
    80005a7c:	644a                	ld	s0,144(sp)
    80005a7e:	64aa                	ld	s1,136(sp)
    80005a80:	690a                	ld	s2,128(sp)
    80005a82:	610d                	addi	sp,sp,160
    80005a84:	8082                	ret
    end_op();
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	798080e7          	jalr	1944(ra) # 8000421e <end_op>
    return -1;
    80005a8e:	557d                	li	a0,-1
    80005a90:	b7ed                	j	80005a7a <sys_chdir+0x7a>
    iunlockput(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	fb0080e7          	jalr	-80(ra) # 80003a44 <iunlockput>
    end_op();
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	782080e7          	jalr	1922(ra) # 8000421e <end_op>
    return -1;
    80005aa4:	557d                	li	a0,-1
    80005aa6:	bfd1                	j	80005a7a <sys_chdir+0x7a>

0000000080005aa8 <sys_exec>:

uint64
sys_exec(void)
{
    80005aa8:	7145                	addi	sp,sp,-464
    80005aaa:	e786                	sd	ra,456(sp)
    80005aac:	e3a2                	sd	s0,448(sp)
    80005aae:	ff26                	sd	s1,440(sp)
    80005ab0:	fb4a                	sd	s2,432(sp)
    80005ab2:	f74e                	sd	s3,424(sp)
    80005ab4:	f352                	sd	s4,416(sp)
    80005ab6:	ef56                	sd	s5,408(sp)
    80005ab8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aba:	08000613          	li	a2,128
    80005abe:	f4040593          	addi	a1,s0,-192
    80005ac2:	4501                	li	a0,0
    80005ac4:	ffffd097          	auipc	ra,0xffffd
    80005ac8:	186080e7          	jalr	390(ra) # 80002c4a <argstr>
    return -1;
    80005acc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ace:	0c054a63          	bltz	a0,80005ba2 <sys_exec+0xfa>
    80005ad2:	e3840593          	addi	a1,s0,-456
    80005ad6:	4505                	li	a0,1
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	150080e7          	jalr	336(ra) # 80002c28 <argaddr>
    80005ae0:	0c054163          	bltz	a0,80005ba2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ae4:	10000613          	li	a2,256
    80005ae8:	4581                	li	a1,0
    80005aea:	e4040513          	addi	a0,s0,-448
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	280080e7          	jalr	640(ra) # 80000d6e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005af6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005afa:	89a6                	mv	s3,s1
    80005afc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005afe:	02000a13          	li	s4,32
    80005b02:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b06:	00391793          	slli	a5,s2,0x3
    80005b0a:	e3040593          	addi	a1,s0,-464
    80005b0e:	e3843503          	ld	a0,-456(s0)
    80005b12:	953e                	add	a0,a0,a5
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	058080e7          	jalr	88(ra) # 80002b6c <fetchaddr>
    80005b1c:	02054a63          	bltz	a0,80005b50 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b20:	e3043783          	ld	a5,-464(s0)
    80005b24:	c3b9                	beqz	a5,80005b6a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	05c080e7          	jalr	92(ra) # 80000b82 <kalloc>
    80005b2e:	85aa                	mv	a1,a0
    80005b30:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b34:	cd11                	beqz	a0,80005b50 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b36:	6605                	lui	a2,0x1
    80005b38:	e3043503          	ld	a0,-464(s0)
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	082080e7          	jalr	130(ra) # 80002bbe <fetchstr>
    80005b44:	00054663          	bltz	a0,80005b50 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b48:	0905                	addi	s2,s2,1
    80005b4a:	09a1                	addi	s3,s3,8
    80005b4c:	fb491be3          	bne	s2,s4,80005b02 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b50:	10048913          	addi	s2,s1,256
    80005b54:	6088                	ld	a0,0(s1)
    80005b56:	c529                	beqz	a0,80005ba0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b58:	ffffb097          	auipc	ra,0xffffb
    80005b5c:	f2e080e7          	jalr	-210(ra) # 80000a86 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b60:	04a1                	addi	s1,s1,8
    80005b62:	ff2499e3          	bne	s1,s2,80005b54 <sys_exec+0xac>
  return -1;
    80005b66:	597d                	li	s2,-1
    80005b68:	a82d                	j	80005ba2 <sys_exec+0xfa>
      argv[i] = 0;
    80005b6a:	0a8e                	slli	s5,s5,0x3
    80005b6c:	fc040793          	addi	a5,s0,-64
    80005b70:	9abe                	add	s5,s5,a5
    80005b72:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005b76:	e4040593          	addi	a1,s0,-448
    80005b7a:	f4040513          	addi	a0,s0,-192
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	178080e7          	jalr	376(ra) # 80004cf6 <exec>
    80005b86:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b88:	10048993          	addi	s3,s1,256
    80005b8c:	6088                	ld	a0,0(s1)
    80005b8e:	c911                	beqz	a0,80005ba2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b90:	ffffb097          	auipc	ra,0xffffb
    80005b94:	ef6080e7          	jalr	-266(ra) # 80000a86 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b98:	04a1                	addi	s1,s1,8
    80005b9a:	ff3499e3          	bne	s1,s3,80005b8c <sys_exec+0xe4>
    80005b9e:	a011                	j	80005ba2 <sys_exec+0xfa>
  return -1;
    80005ba0:	597d                	li	s2,-1
}
    80005ba2:	854a                	mv	a0,s2
    80005ba4:	60be                	ld	ra,456(sp)
    80005ba6:	641e                	ld	s0,448(sp)
    80005ba8:	74fa                	ld	s1,440(sp)
    80005baa:	795a                	ld	s2,432(sp)
    80005bac:	79ba                	ld	s3,424(sp)
    80005bae:	7a1a                	ld	s4,416(sp)
    80005bb0:	6afa                	ld	s5,408(sp)
    80005bb2:	6179                	addi	sp,sp,464
    80005bb4:	8082                	ret

0000000080005bb6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bb6:	7139                	addi	sp,sp,-64
    80005bb8:	fc06                	sd	ra,56(sp)
    80005bba:	f822                	sd	s0,48(sp)
    80005bbc:	f426                	sd	s1,40(sp)
    80005bbe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	e7e080e7          	jalr	-386(ra) # 80001a3e <myproc>
    80005bc8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bca:	fd840593          	addi	a1,s0,-40
    80005bce:	4501                	li	a0,0
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	058080e7          	jalr	88(ra) # 80002c28 <argaddr>
    return -1;
    80005bd8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bda:	0e054063          	bltz	a0,80005cba <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bde:	fc840593          	addi	a1,s0,-56
    80005be2:	fd040513          	addi	a0,s0,-48
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	de0080e7          	jalr	-544(ra) # 800049c6 <pipealloc>
    return -1;
    80005bee:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bf0:	0c054563          	bltz	a0,80005cba <sys_pipe+0x104>
  fd0 = -1;
    80005bf4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bf8:	fd043503          	ld	a0,-48(s0)
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	50a080e7          	jalr	1290(ra) # 80005106 <fdalloc>
    80005c04:	fca42223          	sw	a0,-60(s0)
    80005c08:	08054c63          	bltz	a0,80005ca0 <sys_pipe+0xea>
    80005c0c:	fc843503          	ld	a0,-56(s0)
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	4f6080e7          	jalr	1270(ra) # 80005106 <fdalloc>
    80005c18:	fca42023          	sw	a0,-64(s0)
    80005c1c:	06054863          	bltz	a0,80005c8c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c20:	4691                	li	a3,4
    80005c22:	fc440613          	addi	a2,s0,-60
    80005c26:	fd843583          	ld	a1,-40(s0)
    80005c2a:	68a8                	ld	a0,80(s1)
    80005c2c:	ffffc097          	auipc	ra,0xffffc
    80005c30:	b04080e7          	jalr	-1276(ra) # 80001730 <copyout>
    80005c34:	02054063          	bltz	a0,80005c54 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c38:	4691                	li	a3,4
    80005c3a:	fc040613          	addi	a2,s0,-64
    80005c3e:	fd843583          	ld	a1,-40(s0)
    80005c42:	0591                	addi	a1,a1,4
    80005c44:	68a8                	ld	a0,80(s1)
    80005c46:	ffffc097          	auipc	ra,0xffffc
    80005c4a:	aea080e7          	jalr	-1302(ra) # 80001730 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c4e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c50:	06055563          	bgez	a0,80005cba <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c54:	fc442783          	lw	a5,-60(s0)
    80005c58:	07f1                	addi	a5,a5,28
    80005c5a:	078e                	slli	a5,a5,0x3
    80005c5c:	97a6                	add	a5,a5,s1
    80005c5e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c62:	fc042503          	lw	a0,-64(s0)
    80005c66:	0571                	addi	a0,a0,28
    80005c68:	050e                	slli	a0,a0,0x3
    80005c6a:	9526                	add	a0,a0,s1
    80005c6c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c70:	fd043503          	ld	a0,-48(s0)
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	9fc080e7          	jalr	-1540(ra) # 80004670 <fileclose>
    fileclose(wf);
    80005c7c:	fc843503          	ld	a0,-56(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	9f0080e7          	jalr	-1552(ra) # 80004670 <fileclose>
    return -1;
    80005c88:	57fd                	li	a5,-1
    80005c8a:	a805                	j	80005cba <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c8c:	fc442783          	lw	a5,-60(s0)
    80005c90:	0007c863          	bltz	a5,80005ca0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c94:	01c78513          	addi	a0,a5,28
    80005c98:	050e                	slli	a0,a0,0x3
    80005c9a:	9526                	add	a0,a0,s1
    80005c9c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ca0:	fd043503          	ld	a0,-48(s0)
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	9cc080e7          	jalr	-1588(ra) # 80004670 <fileclose>
    fileclose(wf);
    80005cac:	fc843503          	ld	a0,-56(s0)
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	9c0080e7          	jalr	-1600(ra) # 80004670 <fileclose>
    return -1;
    80005cb8:	57fd                	li	a5,-1
}
    80005cba:	853e                	mv	a0,a5
    80005cbc:	70e2                	ld	ra,56(sp)
    80005cbe:	7442                	ld	s0,48(sp)
    80005cc0:	74a2                	ld	s1,40(sp)
    80005cc2:	6121                	addi	sp,sp,64
    80005cc4:	8082                	ret
	...

0000000080005cd0 <kernelvec>:
    80005cd0:	7111                	addi	sp,sp,-256
    80005cd2:	e006                	sd	ra,0(sp)
    80005cd4:	e40a                	sd	sp,8(sp)
    80005cd6:	e80e                	sd	gp,16(sp)
    80005cd8:	ec12                	sd	tp,24(sp)
    80005cda:	f016                	sd	t0,32(sp)
    80005cdc:	f41a                	sd	t1,40(sp)
    80005cde:	f81e                	sd	t2,48(sp)
    80005ce0:	fc22                	sd	s0,56(sp)
    80005ce2:	e0a6                	sd	s1,64(sp)
    80005ce4:	e4aa                	sd	a0,72(sp)
    80005ce6:	e8ae                	sd	a1,80(sp)
    80005ce8:	ecb2                	sd	a2,88(sp)
    80005cea:	f0b6                	sd	a3,96(sp)
    80005cec:	f4ba                	sd	a4,104(sp)
    80005cee:	f8be                	sd	a5,112(sp)
    80005cf0:	fcc2                	sd	a6,120(sp)
    80005cf2:	e146                	sd	a7,128(sp)
    80005cf4:	e54a                	sd	s2,136(sp)
    80005cf6:	e94e                	sd	s3,144(sp)
    80005cf8:	ed52                	sd	s4,152(sp)
    80005cfa:	f156                	sd	s5,160(sp)
    80005cfc:	f55a                	sd	s6,168(sp)
    80005cfe:	f95e                	sd	s7,176(sp)
    80005d00:	fd62                	sd	s8,184(sp)
    80005d02:	e1e6                	sd	s9,192(sp)
    80005d04:	e5ea                	sd	s10,200(sp)
    80005d06:	e9ee                	sd	s11,208(sp)
    80005d08:	edf2                	sd	t3,216(sp)
    80005d0a:	f1f6                	sd	t4,224(sp)
    80005d0c:	f5fa                	sd	t5,232(sp)
    80005d0e:	f9fe                	sd	t6,240(sp)
    80005d10:	ca7fc0ef          	jal	ra,800029b6 <kerneltrap>
    80005d14:	6082                	ld	ra,0(sp)
    80005d16:	6122                	ld	sp,8(sp)
    80005d18:	61c2                	ld	gp,16(sp)
    80005d1a:	7282                	ld	t0,32(sp)
    80005d1c:	7322                	ld	t1,40(sp)
    80005d1e:	73c2                	ld	t2,48(sp)
    80005d20:	7462                	ld	s0,56(sp)
    80005d22:	6486                	ld	s1,64(sp)
    80005d24:	6526                	ld	a0,72(sp)
    80005d26:	65c6                	ld	a1,80(sp)
    80005d28:	6666                	ld	a2,88(sp)
    80005d2a:	7686                	ld	a3,96(sp)
    80005d2c:	7726                	ld	a4,104(sp)
    80005d2e:	77c6                	ld	a5,112(sp)
    80005d30:	7866                	ld	a6,120(sp)
    80005d32:	688a                	ld	a7,128(sp)
    80005d34:	692a                	ld	s2,136(sp)
    80005d36:	69ca                	ld	s3,144(sp)
    80005d38:	6a6a                	ld	s4,152(sp)
    80005d3a:	7a8a                	ld	s5,160(sp)
    80005d3c:	7b2a                	ld	s6,168(sp)
    80005d3e:	7bca                	ld	s7,176(sp)
    80005d40:	7c6a                	ld	s8,184(sp)
    80005d42:	6c8e                	ld	s9,192(sp)
    80005d44:	6d2e                	ld	s10,200(sp)
    80005d46:	6dce                	ld	s11,208(sp)
    80005d48:	6e6e                	ld	t3,216(sp)
    80005d4a:	7e8e                	ld	t4,224(sp)
    80005d4c:	7f2e                	ld	t5,232(sp)
    80005d4e:	7fce                	ld	t6,240(sp)
    80005d50:	6111                	addi	sp,sp,256
    80005d52:	10200073          	sret
    80005d56:	00000013          	nop
    80005d5a:	00000013          	nop
    80005d5e:	0001                	nop

0000000080005d60 <timervec>:
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	e10c                	sd	a1,0(a0)
    80005d66:	e510                	sd	a2,8(a0)
    80005d68:	e914                	sd	a3,16(a0)
    80005d6a:	710c                	ld	a1,32(a0)
    80005d6c:	7510                	ld	a2,40(a0)
    80005d6e:	6194                	ld	a3,0(a1)
    80005d70:	96b2                	add	a3,a3,a2
    80005d72:	e194                	sd	a3,0(a1)
    80005d74:	4589                	li	a1,2
    80005d76:	14459073          	csrw	sip,a1
    80005d7a:	6914                	ld	a3,16(a0)
    80005d7c:	6510                	ld	a2,8(a0)
    80005d7e:	610c                	ld	a1,0(a0)
    80005d80:	34051573          	csrrw	a0,mscratch,a0
    80005d84:	30200073          	mret
	...

0000000080005d8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d8a:	1141                	addi	sp,sp,-16
    80005d8c:	e422                	sd	s0,8(sp)
    80005d8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d90:	0c0007b7          	lui	a5,0xc000
    80005d94:	4705                	li	a4,1
    80005d96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d98:	c3d8                	sw	a4,4(a5)
}
    80005d9a:	6422                	ld	s0,8(sp)
    80005d9c:	0141                	addi	sp,sp,16
    80005d9e:	8082                	ret

0000000080005da0 <plicinithart>:

void
plicinithart(void)
{
    80005da0:	1141                	addi	sp,sp,-16
    80005da2:	e406                	sd	ra,8(sp)
    80005da4:	e022                	sd	s0,0(sp)
    80005da6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c6a080e7          	jalr	-918(ra) # 80001a12 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005db0:	0085171b          	slliw	a4,a0,0x8
    80005db4:	0c0027b7          	lui	a5,0xc002
    80005db8:	97ba                	add	a5,a5,a4
    80005dba:	40200713          	li	a4,1026
    80005dbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dc2:	00d5151b          	slliw	a0,a0,0xd
    80005dc6:	0c2017b7          	lui	a5,0xc201
    80005dca:	953e                	add	a0,a0,a5
    80005dcc:	00052023          	sw	zero,0(a0)
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret

0000000080005dd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dd8:	1141                	addi	sp,sp,-16
    80005dda:	e406                	sd	ra,8(sp)
    80005ddc:	e022                	sd	s0,0(sp)
    80005dde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de0:	ffffc097          	auipc	ra,0xffffc
    80005de4:	c32080e7          	jalr	-974(ra) # 80001a12 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005de8:	00d5179b          	slliw	a5,a0,0xd
    80005dec:	0c201537          	lui	a0,0xc201
    80005df0:	953e                	add	a0,a0,a5
  return irq;
}
    80005df2:	4148                	lw	a0,4(a0)
    80005df4:	60a2                	ld	ra,8(sp)
    80005df6:	6402                	ld	s0,0(sp)
    80005df8:	0141                	addi	sp,sp,16
    80005dfa:	8082                	ret

0000000080005dfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dfc:	1101                	addi	sp,sp,-32
    80005dfe:	ec06                	sd	ra,24(sp)
    80005e00:	e822                	sd	s0,16(sp)
    80005e02:	e426                	sd	s1,8(sp)
    80005e04:	1000                	addi	s0,sp,32
    80005e06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	c0a080e7          	jalr	-1014(ra) # 80001a12 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e10:	00d5151b          	slliw	a0,a0,0xd
    80005e14:	0c2017b7          	lui	a5,0xc201
    80005e18:	97aa                	add	a5,a5,a0
    80005e1a:	c3c4                	sw	s1,4(a5)
}
    80005e1c:	60e2                	ld	ra,24(sp)
    80005e1e:	6442                	ld	s0,16(sp)
    80005e20:	64a2                	ld	s1,8(sp)
    80005e22:	6105                	addi	sp,sp,32
    80005e24:	8082                	ret

0000000080005e26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e26:	1141                	addi	sp,sp,-16
    80005e28:	e406                	sd	ra,8(sp)
    80005e2a:	e022                	sd	s0,0(sp)
    80005e2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e2e:	479d                	li	a5,7
    80005e30:	04a7cc63          	blt	a5,a0,80005e88 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e34:	0001e797          	auipc	a5,0x1e
    80005e38:	1cc78793          	addi	a5,a5,460 # 80024000 <disk>
    80005e3c:	00a78733          	add	a4,a5,a0
    80005e40:	6789                	lui	a5,0x2
    80005e42:	97ba                	add	a5,a5,a4
    80005e44:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e48:	eba1                	bnez	a5,80005e98 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e4a:	00451713          	slli	a4,a0,0x4
    80005e4e:	00020797          	auipc	a5,0x20
    80005e52:	1b27b783          	ld	a5,434(a5) # 80026000 <disk+0x2000>
    80005e56:	97ba                	add	a5,a5,a4
    80005e58:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e5c:	0001e797          	auipc	a5,0x1e
    80005e60:	1a478793          	addi	a5,a5,420 # 80024000 <disk>
    80005e64:	97aa                	add	a5,a5,a0
    80005e66:	6509                	lui	a0,0x2
    80005e68:	953e                	add	a0,a0,a5
    80005e6a:	4785                	li	a5,1
    80005e6c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e70:	00020517          	auipc	a0,0x20
    80005e74:	1a850513          	addi	a0,a0,424 # 80026018 <disk+0x2018>
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	592080e7          	jalr	1426(ra) # 8000240a <wakeup>
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	8f850513          	addi	a0,a0,-1800 # 80008780 <syscalls+0x340>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	750080e7          	jalr	1872(ra) # 800005e0 <panic>
    panic("virtio_disk_intr 2");
    80005e98:	00003517          	auipc	a0,0x3
    80005e9c:	90050513          	addi	a0,a0,-1792 # 80008798 <syscalls+0x358>
    80005ea0:	ffffa097          	auipc	ra,0xffffa
    80005ea4:	740080e7          	jalr	1856(ra) # 800005e0 <panic>

0000000080005ea8 <virtio_disk_init>:
{
    80005ea8:	1101                	addi	sp,sp,-32
    80005eaa:	ec06                	sd	ra,24(sp)
    80005eac:	e822                	sd	s0,16(sp)
    80005eae:	e426                	sd	s1,8(sp)
    80005eb0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005eb2:	00003597          	auipc	a1,0x3
    80005eb6:	8fe58593          	addi	a1,a1,-1794 # 800087b0 <syscalls+0x370>
    80005eba:	00020517          	auipc	a0,0x20
    80005ebe:	1ee50513          	addi	a0,a0,494 # 800260a8 <disk+0x20a8>
    80005ec2:	ffffb097          	auipc	ra,0xffffb
    80005ec6:	d20080e7          	jalr	-736(ra) # 80000be2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	4398                	lw	a4,0(a5)
    80005ed0:	2701                	sext.w	a4,a4
    80005ed2:	747277b7          	lui	a5,0x74727
    80005ed6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eda:	0ef71163          	bne	a4,a5,80005fbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	43dc                	lw	a5,4(a5)
    80005ee4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ee6:	4705                	li	a4,1
    80005ee8:	0ce79a63          	bne	a5,a4,80005fbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eec:	100017b7          	lui	a5,0x10001
    80005ef0:	479c                	lw	a5,8(a5)
    80005ef2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ef4:	4709                	li	a4,2
    80005ef6:	0ce79363          	bne	a5,a4,80005fbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005efa:	100017b7          	lui	a5,0x10001
    80005efe:	47d8                	lw	a4,12(a5)
    80005f00:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f02:	554d47b7          	lui	a5,0x554d4
    80005f06:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f0a:	0af71963          	bne	a4,a5,80005fbc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0e:	100017b7          	lui	a5,0x10001
    80005f12:	4705                	li	a4,1
    80005f14:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f16:	470d                	li	a4,3
    80005f18:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f1a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f1c:	c7ffe737          	lui	a4,0xc7ffe
    80005f20:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005f24:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f26:	2701                	sext.w	a4,a4
    80005f28:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f2a:	472d                	li	a4,11
    80005f2c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f2e:	473d                	li	a4,15
    80005f30:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f32:	6705                	lui	a4,0x1
    80005f34:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f36:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f3a:	5bdc                	lw	a5,52(a5)
    80005f3c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f3e:	c7d9                	beqz	a5,80005fcc <virtio_disk_init+0x124>
  if(max < NUM)
    80005f40:	471d                	li	a4,7
    80005f42:	08f77d63          	bgeu	a4,a5,80005fdc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f46:	100014b7          	lui	s1,0x10001
    80005f4a:	47a1                	li	a5,8
    80005f4c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f4e:	6609                	lui	a2,0x2
    80005f50:	4581                	li	a1,0
    80005f52:	0001e517          	auipc	a0,0x1e
    80005f56:	0ae50513          	addi	a0,a0,174 # 80024000 <disk>
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	e14080e7          	jalr	-492(ra) # 80000d6e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f62:	0001e717          	auipc	a4,0x1e
    80005f66:	09e70713          	addi	a4,a4,158 # 80024000 <disk>
    80005f6a:	00c75793          	srli	a5,a4,0xc
    80005f6e:	2781                	sext.w	a5,a5
    80005f70:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f72:	00020797          	auipc	a5,0x20
    80005f76:	08e78793          	addi	a5,a5,142 # 80026000 <disk+0x2000>
    80005f7a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f7c:	0001e717          	auipc	a4,0x1e
    80005f80:	10470713          	addi	a4,a4,260 # 80024080 <disk+0x80>
    80005f84:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f86:	0001f717          	auipc	a4,0x1f
    80005f8a:	07a70713          	addi	a4,a4,122 # 80025000 <disk+0x1000>
    80005f8e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f90:	4705                	li	a4,1
    80005f92:	00e78c23          	sb	a4,24(a5)
    80005f96:	00e78ca3          	sb	a4,25(a5)
    80005f9a:	00e78d23          	sb	a4,26(a5)
    80005f9e:	00e78da3          	sb	a4,27(a5)
    80005fa2:	00e78e23          	sb	a4,28(a5)
    80005fa6:	00e78ea3          	sb	a4,29(a5)
    80005faa:	00e78f23          	sb	a4,30(a5)
    80005fae:	00e78fa3          	sb	a4,31(a5)
}
    80005fb2:	60e2                	ld	ra,24(sp)
    80005fb4:	6442                	ld	s0,16(sp)
    80005fb6:	64a2                	ld	s1,8(sp)
    80005fb8:	6105                	addi	sp,sp,32
    80005fba:	8082                	ret
    panic("could not find virtio disk");
    80005fbc:	00003517          	auipc	a0,0x3
    80005fc0:	80450513          	addi	a0,a0,-2044 # 800087c0 <syscalls+0x380>
    80005fc4:	ffffa097          	auipc	ra,0xffffa
    80005fc8:	61c080e7          	jalr	1564(ra) # 800005e0 <panic>
    panic("virtio disk has no queue 0");
    80005fcc:	00003517          	auipc	a0,0x3
    80005fd0:	81450513          	addi	a0,a0,-2028 # 800087e0 <syscalls+0x3a0>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	60c080e7          	jalr	1548(ra) # 800005e0 <panic>
    panic("virtio disk max queue too short");
    80005fdc:	00003517          	auipc	a0,0x3
    80005fe0:	82450513          	addi	a0,a0,-2012 # 80008800 <syscalls+0x3c0>
    80005fe4:	ffffa097          	auipc	ra,0xffffa
    80005fe8:	5fc080e7          	jalr	1532(ra) # 800005e0 <panic>

0000000080005fec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fec:	7175                	addi	sp,sp,-144
    80005fee:	e506                	sd	ra,136(sp)
    80005ff0:	e122                	sd	s0,128(sp)
    80005ff2:	fca6                	sd	s1,120(sp)
    80005ff4:	f8ca                	sd	s2,112(sp)
    80005ff6:	f4ce                	sd	s3,104(sp)
    80005ff8:	f0d2                	sd	s4,96(sp)
    80005ffa:	ecd6                	sd	s5,88(sp)
    80005ffc:	e8da                	sd	s6,80(sp)
    80005ffe:	e4de                	sd	s7,72(sp)
    80006000:	e0e2                	sd	s8,64(sp)
    80006002:	fc66                	sd	s9,56(sp)
    80006004:	f86a                	sd	s10,48(sp)
    80006006:	f46e                	sd	s11,40(sp)
    80006008:	0900                	addi	s0,sp,144
    8000600a:	8aaa                	mv	s5,a0
    8000600c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000600e:	00c52c83          	lw	s9,12(a0)
    80006012:	001c9c9b          	slliw	s9,s9,0x1
    80006016:	1c82                	slli	s9,s9,0x20
    80006018:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000601c:	00020517          	auipc	a0,0x20
    80006020:	08c50513          	addi	a0,a0,140 # 800260a8 <disk+0x20a8>
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	c4e080e7          	jalr	-946(ra) # 80000c72 <acquire>
  for(int i = 0; i < 3; i++){
    8000602c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000602e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006030:	0001ec17          	auipc	s8,0x1e
    80006034:	fd0c0c13          	addi	s8,s8,-48 # 80024000 <disk>
    80006038:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000603a:	4b0d                	li	s6,3
    8000603c:	a0ad                	j	800060a6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000603e:	00fc0733          	add	a4,s8,a5
    80006042:	975e                	add	a4,a4,s7
    80006044:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006048:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000604a:	0207c563          	bltz	a5,80006074 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000604e:	2905                	addiw	s2,s2,1
    80006050:	0611                	addi	a2,a2,4
    80006052:	19690d63          	beq	s2,s6,800061ec <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006056:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006058:	00020717          	auipc	a4,0x20
    8000605c:	fc070713          	addi	a4,a4,-64 # 80026018 <disk+0x2018>
    80006060:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006062:	00074683          	lbu	a3,0(a4)
    80006066:	fee1                	bnez	a3,8000603e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006068:	2785                	addiw	a5,a5,1
    8000606a:	0705                	addi	a4,a4,1
    8000606c:	fe979be3          	bne	a5,s1,80006062 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006070:	57fd                	li	a5,-1
    80006072:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006074:	01205d63          	blez	s2,8000608e <virtio_disk_rw+0xa2>
    80006078:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000607a:	000a2503          	lw	a0,0(s4)
    8000607e:	00000097          	auipc	ra,0x0
    80006082:	da8080e7          	jalr	-600(ra) # 80005e26 <free_desc>
      for(int j = 0; j < i; j++)
    80006086:	2d85                	addiw	s11,s11,1
    80006088:	0a11                	addi	s4,s4,4
    8000608a:	ffb918e3          	bne	s2,s11,8000607a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000608e:	00020597          	auipc	a1,0x20
    80006092:	01a58593          	addi	a1,a1,26 # 800260a8 <disk+0x20a8>
    80006096:	00020517          	auipc	a0,0x20
    8000609a:	f8250513          	addi	a0,a0,-126 # 80026018 <disk+0x2018>
    8000609e:	ffffc097          	auipc	ra,0xffffc
    800060a2:	1ec080e7          	jalr	492(ra) # 8000228a <sleep>
  for(int i = 0; i < 3; i++){
    800060a6:	f8040a13          	addi	s4,s0,-128
{
    800060aa:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060ac:	894e                	mv	s2,s3
    800060ae:	b765                	j	80006056 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060b0:	00020717          	auipc	a4,0x20
    800060b4:	f5073703          	ld	a4,-176(a4) # 80026000 <disk+0x2000>
    800060b8:	973e                	add	a4,a4,a5
    800060ba:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060be:	0001e517          	auipc	a0,0x1e
    800060c2:	f4250513          	addi	a0,a0,-190 # 80024000 <disk>
    800060c6:	00020717          	auipc	a4,0x20
    800060ca:	f3a70713          	addi	a4,a4,-198 # 80026000 <disk+0x2000>
    800060ce:	6314                	ld	a3,0(a4)
    800060d0:	96be                	add	a3,a3,a5
    800060d2:	00c6d603          	lhu	a2,12(a3)
    800060d6:	00166613          	ori	a2,a2,1
    800060da:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060de:	f8842683          	lw	a3,-120(s0)
    800060e2:	6310                	ld	a2,0(a4)
    800060e4:	97b2                	add	a5,a5,a2
    800060e6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800060ea:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800060ee:	0612                	slli	a2,a2,0x4
    800060f0:	962a                	add	a2,a2,a0
    800060f2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060f6:	00469793          	slli	a5,a3,0x4
    800060fa:	630c                	ld	a1,0(a4)
    800060fc:	95be                	add	a1,a1,a5
    800060fe:	6689                	lui	a3,0x2
    80006100:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006104:	96ca                	add	a3,a3,s2
    80006106:	96aa                	add	a3,a3,a0
    80006108:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000610a:	6314                	ld	a3,0(a4)
    8000610c:	96be                	add	a3,a3,a5
    8000610e:	4585                	li	a1,1
    80006110:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006112:	6314                	ld	a3,0(a4)
    80006114:	96be                	add	a3,a3,a5
    80006116:	4509                	li	a0,2
    80006118:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000611c:	6314                	ld	a3,0(a4)
    8000611e:	97b6                	add	a5,a5,a3
    80006120:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006124:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006128:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000612c:	6714                	ld	a3,8(a4)
    8000612e:	0026d783          	lhu	a5,2(a3)
    80006132:	8b9d                	andi	a5,a5,7
    80006134:	0789                	addi	a5,a5,2
    80006136:	0786                	slli	a5,a5,0x1
    80006138:	97b6                	add	a5,a5,a3
    8000613a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000613e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006142:	6718                	ld	a4,8(a4)
    80006144:	00275783          	lhu	a5,2(a4)
    80006148:	2785                	addiw	a5,a5,1
    8000614a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000614e:	100017b7          	lui	a5,0x10001
    80006152:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006156:	004aa783          	lw	a5,4(s5)
    8000615a:	02b79163          	bne	a5,a1,8000617c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000615e:	00020917          	auipc	s2,0x20
    80006162:	f4a90913          	addi	s2,s2,-182 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006166:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006168:	85ca                	mv	a1,s2
    8000616a:	8556                	mv	a0,s5
    8000616c:	ffffc097          	auipc	ra,0xffffc
    80006170:	11e080e7          	jalr	286(ra) # 8000228a <sleep>
  while(b->disk == 1) {
    80006174:	004aa783          	lw	a5,4(s5)
    80006178:	fe9788e3          	beq	a5,s1,80006168 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000617c:	f8042483          	lw	s1,-128(s0)
    80006180:	20048793          	addi	a5,s1,512
    80006184:	00479713          	slli	a4,a5,0x4
    80006188:	0001e797          	auipc	a5,0x1e
    8000618c:	e7878793          	addi	a5,a5,-392 # 80024000 <disk>
    80006190:	97ba                	add	a5,a5,a4
    80006192:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006196:	00020917          	auipc	s2,0x20
    8000619a:	e6a90913          	addi	s2,s2,-406 # 80026000 <disk+0x2000>
    8000619e:	a019                	j	800061a4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800061a0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061a4:	8526                	mv	a0,s1
    800061a6:	00000097          	auipc	ra,0x0
    800061aa:	c80080e7          	jalr	-896(ra) # 80005e26 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061ae:	0492                	slli	s1,s1,0x4
    800061b0:	00093783          	ld	a5,0(s2)
    800061b4:	94be                	add	s1,s1,a5
    800061b6:	00c4d783          	lhu	a5,12(s1)
    800061ba:	8b85                	andi	a5,a5,1
    800061bc:	f3f5                	bnez	a5,800061a0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061be:	00020517          	auipc	a0,0x20
    800061c2:	eea50513          	addi	a0,a0,-278 # 800260a8 <disk+0x20a8>
    800061c6:	ffffb097          	auipc	ra,0xffffb
    800061ca:	b60080e7          	jalr	-1184(ra) # 80000d26 <release>
}
    800061ce:	60aa                	ld	ra,136(sp)
    800061d0:	640a                	ld	s0,128(sp)
    800061d2:	74e6                	ld	s1,120(sp)
    800061d4:	7946                	ld	s2,112(sp)
    800061d6:	79a6                	ld	s3,104(sp)
    800061d8:	7a06                	ld	s4,96(sp)
    800061da:	6ae6                	ld	s5,88(sp)
    800061dc:	6b46                	ld	s6,80(sp)
    800061de:	6ba6                	ld	s7,72(sp)
    800061e0:	6c06                	ld	s8,64(sp)
    800061e2:	7ce2                	ld	s9,56(sp)
    800061e4:	7d42                	ld	s10,48(sp)
    800061e6:	7da2                	ld	s11,40(sp)
    800061e8:	6149                	addi	sp,sp,144
    800061ea:	8082                	ret
  if(write)
    800061ec:	01a037b3          	snez	a5,s10
    800061f0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800061f4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800061f8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800061fc:	f8042483          	lw	s1,-128(s0)
    80006200:	00449913          	slli	s2,s1,0x4
    80006204:	00020997          	auipc	s3,0x20
    80006208:	dfc98993          	addi	s3,s3,-516 # 80026000 <disk+0x2000>
    8000620c:	0009ba03          	ld	s4,0(s3)
    80006210:	9a4a                	add	s4,s4,s2
    80006212:	f7040513          	addi	a0,s0,-144
    80006216:	ffffb097          	auipc	ra,0xffffb
    8000621a:	f28080e7          	jalr	-216(ra) # 8000113e <kvmpa>
    8000621e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006222:	0009b783          	ld	a5,0(s3)
    80006226:	97ca                	add	a5,a5,s2
    80006228:	4741                	li	a4,16
    8000622a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000622c:	0009b783          	ld	a5,0(s3)
    80006230:	97ca                	add	a5,a5,s2
    80006232:	4705                	li	a4,1
    80006234:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006238:	f8442783          	lw	a5,-124(s0)
    8000623c:	0009b703          	ld	a4,0(s3)
    80006240:	974a                	add	a4,a4,s2
    80006242:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006246:	0792                	slli	a5,a5,0x4
    80006248:	0009b703          	ld	a4,0(s3)
    8000624c:	973e                	add	a4,a4,a5
    8000624e:	058a8693          	addi	a3,s5,88
    80006252:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006254:	0009b703          	ld	a4,0(s3)
    80006258:	973e                	add	a4,a4,a5
    8000625a:	40000693          	li	a3,1024
    8000625e:	c714                	sw	a3,8(a4)
  if(write)
    80006260:	e40d18e3          	bnez	s10,800060b0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006264:	00020717          	auipc	a4,0x20
    80006268:	d9c73703          	ld	a4,-612(a4) # 80026000 <disk+0x2000>
    8000626c:	973e                	add	a4,a4,a5
    8000626e:	4689                	li	a3,2
    80006270:	00d71623          	sh	a3,12(a4)
    80006274:	b5a9                	j	800060be <virtio_disk_rw+0xd2>

0000000080006276 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006276:	1101                	addi	sp,sp,-32
    80006278:	ec06                	sd	ra,24(sp)
    8000627a:	e822                	sd	s0,16(sp)
    8000627c:	e426                	sd	s1,8(sp)
    8000627e:	e04a                	sd	s2,0(sp)
    80006280:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006282:	00020517          	auipc	a0,0x20
    80006286:	e2650513          	addi	a0,a0,-474 # 800260a8 <disk+0x20a8>
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	9e8080e7          	jalr	-1560(ra) # 80000c72 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	00020717          	auipc	a4,0x20
    80006296:	d6e70713          	addi	a4,a4,-658 # 80026000 <disk+0x2000>
    8000629a:	02075783          	lhu	a5,32(a4)
    8000629e:	6b18                	ld	a4,16(a4)
    800062a0:	00275683          	lhu	a3,2(a4)
    800062a4:	8ebd                	xor	a3,a3,a5
    800062a6:	8a9d                	andi	a3,a3,7
    800062a8:	cab9                	beqz	a3,800062fe <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062aa:	0001e917          	auipc	s2,0x1e
    800062ae:	d5690913          	addi	s2,s2,-682 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062b2:	00020497          	auipc	s1,0x20
    800062b6:	d4e48493          	addi	s1,s1,-690 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062ba:	078e                	slli	a5,a5,0x3
    800062bc:	97ba                	add	a5,a5,a4
    800062be:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062c0:	20078713          	addi	a4,a5,512
    800062c4:	0712                	slli	a4,a4,0x4
    800062c6:	974a                	add	a4,a4,s2
    800062c8:	03074703          	lbu	a4,48(a4)
    800062cc:	ef21                	bnez	a4,80006324 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062ce:	20078793          	addi	a5,a5,512
    800062d2:	0792                	slli	a5,a5,0x4
    800062d4:	97ca                	add	a5,a5,s2
    800062d6:	7798                	ld	a4,40(a5)
    800062d8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062dc:	7788                	ld	a0,40(a5)
    800062de:	ffffc097          	auipc	ra,0xffffc
    800062e2:	12c080e7          	jalr	300(ra) # 8000240a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062e6:	0204d783          	lhu	a5,32(s1)
    800062ea:	2785                	addiw	a5,a5,1
    800062ec:	8b9d                	andi	a5,a5,7
    800062ee:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062f2:	6898                	ld	a4,16(s1)
    800062f4:	00275683          	lhu	a3,2(a4)
    800062f8:	8a9d                	andi	a3,a3,7
    800062fa:	fcf690e3          	bne	a3,a5,800062ba <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062fe:	10001737          	lui	a4,0x10001
    80006302:	533c                	lw	a5,96(a4)
    80006304:	8b8d                	andi	a5,a5,3
    80006306:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006308:	00020517          	auipc	a0,0x20
    8000630c:	da050513          	addi	a0,a0,-608 # 800260a8 <disk+0x20a8>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	a16080e7          	jalr	-1514(ra) # 80000d26 <release>
}
    80006318:	60e2                	ld	ra,24(sp)
    8000631a:	6442                	ld	s0,16(sp)
    8000631c:	64a2                	ld	s1,8(sp)
    8000631e:	6902                	ld	s2,0(sp)
    80006320:	6105                	addi	sp,sp,32
    80006322:	8082                	ret
      panic("virtio_disk_intr status");
    80006324:	00002517          	auipc	a0,0x2
    80006328:	4fc50513          	addi	a0,a0,1276 # 80008820 <syscalls+0x3e0>
    8000632c:	ffffa097          	auipc	ra,0xffffa
    80006330:	2b4080e7          	jalr	692(ra) # 800005e0 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
