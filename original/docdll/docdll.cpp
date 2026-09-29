#include <afx.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fstream.h>

#define TEXT_WIDTH 72
#define BUFFER_SIZE 16384

unsigned char specs[] =
{ 7, /* tab columns separator - handled specially*/
      '\n',/* hook to handle end of line in tables */
      0x1E,/* unbreakable defis */
      0x1F,/* soft hyphen */
      0x85,/* dots */
      0x91,/* opening single quote */
      0x92,/* closing single quote */
      0x93,/* opening double quote */
      0x94,/* closing double quote */
      0x96,/* em-dash (or em-space)*/
      0x97,/* en-dash */
      0x99,/* Trade Mark sign */
      0xA0,/* unbreakable space */
      0xA9,/* Copyright sign */
      0xAE,/* Reserved sign */
      0xAB,/* opening << quote*/
      0xBB,/* closing >> quote*/
      '\r',/* Ignore paragraph end in tables*/
      /* The rest is translated into itself unless TeX mode is selected */
      '%','$','_','{','}','\\','~','^',
      0 /* To terminate the string, becouse I'm using strchr to search in it*/ 
};

unsigned char *ascii_specs[]=
{
    (unsigned char *) "\t",
	(unsigned char *) "\n",
	(unsigned char *) "-",
	(unsigned char *) "",
	(unsigned char *) "...",
	(unsigned char *) "`",
	(unsigned char *) "'",
	(unsigned char *) "``",
	(unsigned char *) "''",
	(unsigned char *) "-",
	(unsigned char *)"-",
	(unsigned char *)"tm",
    (unsigned char *)" ",
	(unsigned char *)"(c)",
	(unsigned char *)"(R)",
	(unsigned char *)"\"",
	(unsigned char *)"\"",
	(unsigned char *)" ",
	(unsigned char *)"%",
	(unsigned char *)"$",
	(unsigned char *)"_",
	(unsigned char *)"{",
	(unsigned char *)"}",
	(unsigned char *)"\\",
	(unsigned char *)"~",
	(unsigned char *)"^"
};


/*********************************************************************/
/**  code_pade translation                                          **/
/*********************************************************************/

unsigned char table[256]=
{
0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0D,0x0c,0x0d,0x0e,0x0f,
0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x2D,0x20,
0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,
0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f,
0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,0x4d,0x4e,0x4f,
0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x5b,0x5c,0x5d,0x5e,0x5f,
0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x6b,0x6c,0x6d,0x6e,0x6f,
0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x7b,0x7c,0x7d,0x7e,0x7f,
0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f,
0x90,0x60,0x27,0x22,0x22,0x95,0x2D,0x2D,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f,
0x20,0xa1,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0x22,0xac,0xad,0xae,0xaf,
0xb0,0xb1,0xb2,0xb3,'i',0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0x22,0xbc,0xbd,0xbe,0xbf,
0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f,
0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f,
0xa0,0xa1,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xab,0xac,0xad,0xae,0xaf,
0xe0,0xe1,0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xeb,0xec,0xed,0xee,0xef};

#define recode_char(x) table[x]

unsigned char *map_char(unsigned char **map,int c)
{
    static      unsigned char    buffer[2]="a";
                unsigned char    *ptr;

    if ( ( ptr = (unsigned char *)strchr((char *) specs, c)) )
    {
        return map[ ptr - specs ];
    }
    else
    {
        buffer[0]=recode_char(c);
        return buffer;
    }
}


/* ............................................................. func ... */
void format( unsigned char *buf, unsigned char **map, CString& result)
{
    unsigned char    outstring[128];
    unsigned char    *sp = buf;
    int     table = 0;

    outstring[0] = '\0';                        /* clear as "" */

    while (*sp)
    {
        if (*sp==7&&table)
        {			
			result = result + outstring + map_char(map,'\n');
			//printf("%s%s",outstring,map_char(map,'\n'));
            outstring[0]=0;
            table=0;sp++;
        }
        else
        {   
            if ( strlen( strcat((char *) outstring,(char *) map_char( map ,*sp))) > TEXT_WIDTH)
            { 
			   result = result + outstring;
               //printf("%s",outstring);
               *outstring=0;               
            }
            table=*(sp++)==7;
        }
    }
    
    if (outstring[0]!=0) {
		result = result + outstring + "\n";
		//printf("%s\n", outstring);
	}
}

unsigned char buf[BUFFER_SIZE];

void do_file(FILE *f, unsigned char **map, int search_sign, CString& result)
{	
    int ok =! search_sign;
    int bufptr, c;
	
    while( !feof(f) )
    {
		 bufptr = -1;

        do {
			
            c = getc(f);
		

            /* Special printable symbols 7- table separator
             *
             * \r   - paragraph end
             * 0x1E - short defis
             *
             */

            if ((c<=255&&c>=32)||c==7||c=='\t'||c=='\r'||c==0x1E)
                buf[++bufptr]=c;
            else
                if (c==0x0b)
                    buf[++bufptr]='\r';
                else
                {
                    if (!c)
                    {
                        buf[++bufptr]=0;
                        if(!strcmp((char *)buf,"MSWordDoc"))
                        {
                            ok=1;
                        }
                    }
                    if (c!=2)/* \002 is Word's footnote mark */
                        bufptr=-1; /*all other special symbols
                                     discard buffe */
                }
        		
		} while ((c!='\r')&&(c!=EOF));

        if (bufptr>0&&buf[bufptr]=='\r')
        {
            if (!ok)
                exit( 1);
            buf[bufptr]=0;
            format(buf,(unsigned char **) map, result);
        }
    }
}

extern "C" __declspec(dllexport) LPCTSTR ReadWordDocument(LPCSTR FileName){
  int     search_sign = 0;
  CString result;
  unsigned char    **sequences = ascii_specs;  
  FILE *f=fopen(FileName,"rb");  
  if(!f) return NULL;
  do_file(f,sequences,search_sign, result);  
  return strdup((LPCTSTR) result);
}

