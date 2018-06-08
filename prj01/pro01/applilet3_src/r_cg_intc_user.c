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
* File Name    : r_cg_intc_user.c
* Version      : Applilet3 for RL78/L12 V2.04.00.01 [23 Mar 2017]
* Device(s)    : R5F10RLC
* Tool-Chain   : IAR Systems iccrl78
* Description  : This file implements device driver for INTC module.
* Creation Date: 2018/5/23
***********************************************************************************************************************/

/***********************************************************************************************************************
Includes
***********************************************************************************************************************/
#include "r_cg_macrodriver.h"
#include "r_cg_intc.h"
/* Start user code for include. Do not edit comment generated here */
#include "r_cg_port.h"
#include "r_cg_timer.h"
/* End user code. Do not edit comment generated here */
#include "r_cg_userdefine.h"

/***********************************************************************************************************************
Global variables and functions
***********************************************************************************************************************/
/* Start user code for global. Do not edit comment generated here */
int16_t temp_count =0;

//����9�� 1 ��ʼ�����ݣ���ʶΪ1 ���м��յ����������Σ����Ϊ0
uint8_t gStart=0;
//��ǰ���ܵ��ڼ�λ
uint8_t gDataLen=0;
//recive data
uint8_t gData[64];
//������״̬��¼ 
uint8_t gDataHalf=0;
//�Ƿ����һ���λ���ݣ���Ϊ0 ����1
uint8_t gIsHalf=0;
//��ʼ���
uint8_t gIsHead=0;
//id ����16HEX
uint8_t gCard=0;
uint8_t gCardStr[12];

//extern int16_t count_pluse
/* End user code. Do not edit comment generated here */

/***********************************************************************************************************************
* Function Name: r_intc4_interrupt
* Description  : This function is INTP4 interrupt service routine.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
#pragma vector = INTP4_vect
__interrupt static void r_intc4_interrupt(void)
{
    /* Start user code. Do not edit comment generated here */    
    temp_count = count_pluse;
    count_pluse = 0;
    manchest();
    /* End user code. Do not edit comment generated here */
}




/* Start user code for adding. Do not edit comment generated here */
void Test_H(void){
    P14 = P14 | 0X04;
}
void Test_L(void){
    P14 = P14 & 0XFB;
}

/****************************************************************************
* ��    �ƣ�manchest(void)
* ��    �ܣ�����˹��������� ���� ��->�� Ϊ1  ��->�� Ϊ0 
* ��ڲ�������
* ���ڲ�������
* ˵    ����
* ���÷������� 
* ���ߣ� 
****************************************************************************/
void manchest(void)
{
    uint8_t dHalf=0;
    //�Ӳ�����	
    if( temp_count<6 ) 
    {
          count_pluse=0;
          return;
    }
    if(gStart==0)
    {
          if(temp_count>320 && temp_count<380)
          {
                gStart = 1;
          }
    }
    else
    {

          //140us -- 288us  ||  440us-- 640us  [110 , 160]
          if( temp_count>35 && temp_count<72 )
          {     //���յ�����������
                dHalf =  ( P3<<2 && 0X01 );
                //��¼�����ڵ�״̬
                if( gIsHalf==0 )
                {
                      gDataHalf = dHalf;
                      gIsHalf=1;		//����Ϊ�ѽ���һ������
                }
                else
                {
                      Test_H();
                      gIsHalf=0;		//����Ϊ�ѽ������һλ����
                      if( gDataHalf==1 && dHalf==0 )
                      {
                              gData[ gDataLen++ ] = 1;
                      }
                      else if( gDataHalf==0 && dHalf==1 ) 
                      {
                              gData[ gDataLen++ ] = 0;
                      }
                      Test_L();
                }
          }
          //ȫ���Σ�һ������һλ���ݵ�һ�룬��������λ��ǰ�벿�֣�
          else if(temp_count>110 && temp_count<160)
          {
                dHalf =  ( P3<<2 && 0X01 );
                if( gIsHalf==1 )
                {
                      Test_H();
                      //���ǰ�����ڵ����ݣ�����һλ
                      if( gDataHalf==1 && dHalf==0 )
                      {
                              gData[ gDataLen++ ] = 1;
                      }
                      else if( gDataHalf==0 && dHalf==1 )
                      {
                              gData[ gDataLen++ ] = 0;
                      }
                      gDataHalf = dHalf;
                      Test_L();
                }
                else
                {
                      //���¿�ʼ���
                      //gIsHalf=0;
                      //gDataLen=0;
                      //gStart=0;
                      gIsHalf=1;
                      gDataHalf = dHalf;
                }
          }
    }
    //���������
    if( gDataLen==64 )
    {
            Test_H();
            gIsHalf=0;
            gDataLen=0;
            gStart=0;
            gIsHead=0;
            Test_L();
                                    
    }
}
/* End user code. Do not edit comment generated here */
