/***********************************************************************************************************************
* DISCLAIMER
* This software is supplied by Renesas Electronics Corporation and is only intended for use with Renesas products.
* No other uses are authorized. This software is owned by Renesas Electronics Corporation and is protected under all
* applicable laws, including copyright laws. 
* THIS SOFTWARE IS PROVIDED "AS IS" AND RENESAS MAKES NO WARRANTIESREGARDING THIS SOFTWARE, WHETHER EXPRESS, IMPLIED
* OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NON-INFRINGEMENT.  ALL SUCH WARRANTIES ARE EXPRESSLY DISCLAIMED.TO THE MAXIMUM EXTENT PERMITTED NOT PROHIBITED BY
* LAW, NEITHER RENESAS ELECTRONICS CORPORATION NOR ANY OF ITS AFFILIATED COMPANIES SHALL BE LIABLE FOR ANY DIRECT,
* INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES FOR ANY REASON RELATED TO THIS SOFTWARE, EVEN IF RENESAS OR
* ITS AFFILIATES HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
* Renesas reserves the right, without notice, to make changes to this software and to discontinue the availability 
* of this software. By using this software, you agree to the additional terms and conditions found by accessing the 
* following link:
* http://www.renesas.com/disclaimer
*
* Copyright (C) 2012, 2017 Renesas Electronics Corporation. All rights reserved.
***********************************************************************************************************************/

/***********************************************************************************************************************
* File Name    : r_main.c
* Version      : Applilet3 for RL78/L12 V2.04.00.01 [23 Mar 2017]
* Device(s)    : R5F10RLC
* Tool-Chain   : IAR Systems iccrl78
* Description  : This file implements main function.
* Creation Date: 2018/5/23
***********************************************************************************************************************/

/***********************************************************************************************************************
Includes
***********************************************************************************************************************/
#include "r_cg_macrodriver.h"
#include "r_cg_cgc.h"
#include "r_cg_port.h"
#include "r_cg_intc.h"
#include "r_cg_timer.h"
#include "r_cg_wdt.h"
#include "r_cg_lcd.h"
/* Start user code for include. Do not edit comment generated here */
/* End user code. Do not edit comment generated here */
#include "r_cg_userdefine.h"

/***********************************************************************************************************************
Global variables and functions
***********************************************************************************************************************/
/* Start user code for global. Do not edit comment generated here */
#define Start_Gap_Num	40//43//29//40;   //��ʼ��϶ �� 10~50��������FC,����ȡ40		350		
#define Write_Gap_Num	19//37//17//19;   //д��϶	  �� 8~30��������FC,����ȡ19		300
#define Write_Data1_Num	56//50//54//56;	//д����'1' ,48~63��������FC,����ȡ56		400
#define Write_Data0_Num	24//17//22//24;	 //д����'0' ,16~31��������FC,����ȡ24		140
//T55xx  command
#define ReSetCommand	0x00
#define StandardWrite10	0x02
#define StandardWrite11	0x03
#define TH0_720us  0xfd	 //T5557 ��Ƭ��һ��ͬ��ͷ�ж϶�ʱ��
#define TL0_720us  0x68	 //720us						 gai

#define	TH0_650us  0xfd  //T5557 ��Ƭ�ڶ���ͬ��ͷ�ж϶�ʱ��
#define	TL0_650us  0xa8  //650us					   gai

#define	T_Star  0xF9FFU// T5557 ��Ƭ���� POR ��ʱֵ�趨Ϊ4ms  Ϊд�����ĵ�һ�� GAP			   gai

#define	TH0_T557  0xfe// T5557 ��Ƭ����ȡ����ʱֵ�趨Ϊ350us
#define	TL0_T557  0xbd// 

#define	T_1  0x18FFU// ��ʱ��0 ��ʱֵ�趨Ϊ350us	gai 400 Ϊд��1��GAP

#define	T_0  0x09FFU// ��ʱ��0 ��ʱֵ�趨Ϊ100us	 gai 160 Ϊд��0��GAP		   

#define	T_w  0x09FFU// ��ʱ��0 ��ʱֵ�趨Ϊ250us Ϊд��write��GAP			   gai 160
#define TH0_67 0X12
#define TL0_67 0X66

unsigned char LOCK00=0,LOCK01=0,LOCK02=0,LOCK03=0,LOCK04=0,LOCK05=0,LOCK06=0,LOCK07=0;
unsigned char LOCK11=0,LOCK12=0; //����������λ��ʼ����ȫ����ʼ��Ϊδ��״̬

const unsigned char InitT55xxDataArr[4]={0x00,0x14,0x80,0x00};
const unsigned char Pre_InitT55xxDataArr[4]={0x00,0x80,0x80,0xE8};
unsigned char Block_data1[4]={0xFE,0xFE,0xFE,0xFE};
unsigned char Block_data2[4]={0xFF,0xFF,0xFF,0xFF};
unsigned char Block_data3[4]={0xFF,0xFF,0xFF,0xFF};
unsigned char Block_data4[4]={0xFF,0xFF,0xFF,0xFF};
unsigned char Block_data5[4]={0xFF,0xFF,0xFF,0xFF};
unsigned char Block_data6[4]={0xFF,0xFF,0xFF,0xFF};

unsigned char data_tap[4]= {4,4,4,4};

unsigned char tap;//tap Ϊ����˹������뷢��ʱ����ʱ���㻺��

void delayms(){
   unsigned char i,j;
   for(i=15;i>0;i--)
     for(j=202;j>0;j--);
}

/* End user code. Do not edit comment generated here */

/* Set option bytes */
#pragma constseg = __far "OPTBYTE"
__root const uint8_t opbyte0 = 0xFFU;
__root const uint8_t opbyte1 = 0xFFU;
__root const uint8_t opbyte2 = 0xE9U;
__root const uint8_t opbyte3 = 0x04U;
#pragma constseg = default

/* Set security ID */
#pragma constseg = __far "SECUID"
__root const uint8_t secuid[10] = 
	{0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U};
#pragma constseg = default

void R_MAIN_UserInit(void);

/***********************************************************************************************************************
* Function Name: main
* Description  : This function implements main function.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void main(void)
{
    R_MAIN_UserInit();
    /* Start user code. Do not edit comment generated here */
    R_TAU0_Channel0_Start();    //RF On 125Khz
    R_TAU0_Channel1_Start();
    R_LCD_Start();
    R_LCD_Set_VoltageOn();
    SEG0 = 0XFF;
    R_INTC4_Start();
    delayms();
    //Card_initialization();
    //Standard_Write_T5577(0X02,LOCK01,Block_data1,0X01);
    Read_0_Page_block();
    delayms();
    R_TAU0_Channel0_Start();    //RF On 125Khz
    while (1U)
    {
    }
    /* End user code. Do not edit comment generated here */
}


/***********************************************************************************************************************
* Function Name: R_MAIN_UserInit
* Description  : This function adds user code before implementing main function.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void R_MAIN_UserInit(void)
{
    /* Start user code. Do not edit comment generated here */
    EI();
    /* End user code. Do not edit comment generated here */
}

/* Start user code for adding. Do not edit comment generated here */
// ��ȷ��ʱn�������ڣ���8nus��125KHz��
// ��n=1ʱ����ʱ8us
void delay_8nus(unsigned char n)
{
    count_8us =0;
    R_TAU0_Channel2_Start();//������ʱ��2����ʱʱ��Ϊ8us
    while(count_8us != n);
    R_TAU0_Channel2_Stop();    
}
//�ز���
void Carrier_On(void)
{
    R_TAU0_Channel0_Start();    //RF On 125Khz
}
//�ز��ر�
void Carrier_Off(void)
{
    R_TAU0_Channel0_Stop();    //RF On 125Khz
}
//	��ʼ��϶ �� 10~50��������FC
void Start_Gap(void)
{
    Carrier_Off();
    delay_8nus(Start_Gap_Num);
}
//����ģʽ��д��϶
void Write_Gap(void)
{
    Carrier_Off();
    delay_8nus(Write_Gap_Num);	
}

//����ģʽ��д����'0'
void Write_Data0(void)
{	
    Carrier_On();
    delay_8nus(Write_Data0_Num);
}

//����ģʽ��д����'1'
void Write_Data1(void)
{	
    Carrier_On();
    delay_8nus(Write_Data1_Num);
}
///////////////////////////////////////////////////////////////////////////
////  ��������  void U2270B_SendOpcode(unsigned char op)
//    ��  ����  opΪ�����͵Ĳ����룬ֻ��ȡ 10B ��11B
//    �������ܣ�������λ����������,�������� op����׼д���� op ֻ��ȡ 10B ��11B
void SendOpcode(unsigned char opcod)
{
	unsigned char mask = 0x02,i;
	for(i=0;i<2;i++)
	{
		if(mask & opcod)
		{
			Write_Data1();
		}
		else
		{
		  	Write_Data0();		  
		}
		Write_Gap();
		mask >>= 1;
	}
Carrier_On();///////////��� ��һ���õ�	
}
//////////////////////////////////////////////////////////
//  ��������  void SendLock(unsigned char lock)
//  ��  ����  lockΪҪ���͵�����λ
//  �������ܣ�����һλ����λ���� lock
void SendLock(unsigned char lck)
{
        if(0x01 & lck)
        {
                Write_Data1();
        }
        else
        {
                Write_Data0();
        }
        Write_Gap();	
}
//////////////////////////////////////////////////////////
//  ��������  void SendByte(unsigned char byte)
//  ��  ����  byteΪҪ���͵��ֽ�����
//  �������ܣ�����һ���ֽڵ�����byte
void SendByte(unsigned char byte)
{
	unsigned char mask = 0x80,i;
	for(i=0;i<8;i++)
	{
		if(mask & byte)
		{
			Write_Data1();
		}
		else
		{
		  	Write_Data0();		  
		}
		Write_Gap();
		mask >>= 1;
	}	
}
///////////////////////////////////////////////////////////////////////////
////  ��������  void SendAddress(unsigned char blk)
//    ��  ����  blkΪ��д�����ݵĿ�����
//    �������ܣ�����3λ�ĵ�ַ����blk ����blk��
void SendAddress(unsigned char block)
{
	unsigned char mask = 0x04,i;
	for(i=0;i<3;i++)
	{
		if(mask & block)
		{
			Write_Data1();
		}
		else
		{
		  	Write_Data0();
		}
		Write_Gap();
		mask >>= 1;
	}	
}
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//   �������� Standard_Write_T5577(uchar lock,uchar opcode,uchar data_arr[4],uchar block)
//   ��  ���� lockΪҪ���͵�����λ��blockΪ��д�����ݵĿ�����	,opcodeΪ�����͵Ĳ����룬data_arr[4]ΪҪ���͵�4�ֽ�����
void Standard_Write_T5577(unsigned char opcode,unsigned char lock,unsigned char data_arr[4],unsigned char block)
{
       Start_Gap();
       SendOpcode(opcode);	  	//10		2
       SendLock(lock);			//0		1
       SendByte(data_arr[0]);		//		4
       SendByte(data_arr[1]);		//		4
       SendByte(data_arr[2]);		//		4
       SendByte(data_arr[3]);		//		4
       SendAddress(block);		//		3
}
void Card_initialization()//��ʼ����Ƭ
{
       Start_Gap();
       SendOpcode(0X02);	//10		2
       SendLock(0X00);		//0		1
       SendByte(InitT55xxDataArr[0]);		//		4
       SendByte(InitT55xxDataArr[1]);		//		4
       SendByte(InitT55xxDataArr[2]);		//		4
       SendByte(InitT55xxDataArr[3]);		//		4
       SendAddress(0X00);        	
}
void  Data_Processing()//���ݴ���
{
	if(tap==0x01)
	{
                ///////////////////////д 1
                TDR03 = T_1;
                //R_TAU0_Channel3_Start();
		TR3=1;
		//CLK=1;
		while(TR3==1);		
	 }
	 else
	 {
                ///////////////////////д 0
                TDR03 = T_0;
                //R_TAU0_Channel3_Start();
		TR3=1;
		while(TR3==1);
	 }
        //////////////////////��϶
   	TDR03 = T_w;
	TR3=1;
	while(TR3==1);
}
void write_od(unsigned char voled)//д���� voled Ϊ������
{
        TDR03 = T_Star;//4ms �ȴ�0���������>3ms
        //R_TAU0_Channel3_Start();
	TR3=1;
	while(TR3==1);
        //////////////////// ���
        TDR03 = T_1;//400us
        //R_TAU0_Channel3_Start();
	TR3=1;
	while(TR3==1);
	tap=voled;
	tap&=0x10;
	if(tap==0x10)
	{
		tap=0x01;
		Data_Processing();//
	}
	else 
	{
		tap=0x00;
		Data_Processing();//
	}
	tap=voled;
	tap&=0x01;
	Data_Processing();//	
}
void  write_lock(unsigned char voled)//д����λ
{
	tap=voled;
	tap&=0x01;
	Data_Processing();//
}
void write_data()//д����
{
   unsigned char i,j,voled_1;
	for(j=0;j<4;j++)
	{
	  	voled_1=data_tap[j];
		for(i=0;i<8;i++)
		{ 
			tap=voled_1;
	   		tap&=0x01;
	   		Data_Processing();//
	   		voled_1>>=1;
	   	}
	}
}
void write_add(unsigned char voled)//д��ַ
{
	tap=voled;
	tap&=0x04;
	if(tap==0x04)
	{
		tap=0x01;
		Data_Processing();//
	}
	else 
	{
		tap=0x00;
		Data_Processing();//
	}
//////////////////////////////////////
	tap=voled;
	tap&=0x02;
	if(tap==0x02)
	{
		tap=0x01;
		Data_Processing();//
	}
	else 
	{
		tap=0x00;
		Data_Processing();//
	}
////////////////////////////////////////
	tap=voled;
	tap&=0x01;
	Data_Processing();//	
}
void REM_Processing()//����˹����������ȡ
{
	   	 		
}
void Write_0_Page()//д��0ҳ��Ϣ 
{
      write_od(0x10);//д����
      write_lock(LOCK00);//д����λ
      write_data();//д����
      write_add(0X01);//д��ַ
      //delay(100);	
      REM_Processing();//����˹����������ȡ;	
}
void Read_0_Page_block()	 //���0ҳ
 {
     Start_Gap();
     SendOpcode(0X02);	//10		2
     SendLock(0X00);		//0		1
     SendAddress(0X01);  

}
/* End user code. Do not edit comment generated here */
