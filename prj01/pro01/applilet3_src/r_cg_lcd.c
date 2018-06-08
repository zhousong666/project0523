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
* File Name    : r_cg_lcd.c
* Version      : Applilet3 for RL78/L12 V2.04.00.01 [23 Mar 2017]
* Device(s)    : R5F10RLC
* Tool-Chain   : IAR Systems iccrl78
* Description  : This file implements device driver for LCD module.
* Creation Date: 2018/5/23
***********************************************************************************************************************/

/***********************************************************************************************************************
Includes
***********************************************************************************************************************/
#include "r_cg_macrodriver.h"
#include "r_cg_lcd.h"
/* Start user code for include. Do not edit comment generated here */
/* End user code. Do not edit comment generated here */
#include "r_cg_userdefine.h"

/***********************************************************************************************************************
Global variables and functions
***********************************************************************************************************************/
/* Start user code for global. Do not edit comment generated here */
/* End user code. Do not edit comment generated here */

/***********************************************************************************************************************
* Function Name: R_LCD_Create
* Description  : This function initializes the LCD module.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void R_LCD_Create(void)
{
    RTCEN = 1U;    /* supply LCD clock */
    LCDON = 0U;    /* disable LCD clock operation */
    LCDM0 = _00_LCD_DISPLAY_WAVEFORM_A | _00_LCD_DISPLAY_STATIC;
    LCDM0 |= _00_LCD_VOLTAGE_MODE_EXTERNAL;
    /* Set segment pins */
    PFSEG0 |= 0xF0U;
    PFSEG1 |= 0x3FU;
    PFSEG2 |= 0x00U;
    PFSEG3 |= 0x00U;
    PFSEG4 |= 0x00U;
    POM1 &= 0x5FU;
    PIM1 &= 0x9FU;
    PU1 &= 0x1FU;
    P1 &= 0x1FU;
    PM1 &= 0x1FU;
    PU5 &= 0xE0U;
    P5 &= 0xE0U;
    PM5 &= 0xE0U;
    PU7 &= 0xE7U;
    P7 &= 0xE7U;
    PM7 &= 0xE7U;
    LCDM1 |= _00_LCD_DISPLAY_PATTERN_A;
    LCDC0 = _06_LCD_CLOCK_FSUB_FIL_7;
}

/***********************************************************************************************************************
* Function Name: R_LCD_Start
* Description  : This function enables the LCD display.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void R_LCD_Start(void)
{
    LCDON = 1U;
}

/***********************************************************************************************************************
* Function Name: R_LCD_Stop
* Description  : This function disables the LCD display.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void R_LCD_Stop(void)
{
    LCDON = 0U;
}

/***********************************************************************************************************************
* Function Name: R_LCD_Set_VoltageOn
* Description  : This function enables voltage boost circuit or capacitor split circuit.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void R_LCD_Set_VoltageOn(void)
{
    SCOC = 1U;
}

/***********************************************************************************************************************
* Function Name: R_LCD_Set_VoltageOff
* Description  : This function disables voltage boost circuit or capacitor split circuit.
* Arguments    : None
* Return Value : None
***********************************************************************************************************************/
void R_LCD_Set_VoltageOff(void)
{
    SCOC = 0U;
}

/* Start user code for adding. Do not edit comment generated here */
/* End user code. Do not edit comment generated here */
