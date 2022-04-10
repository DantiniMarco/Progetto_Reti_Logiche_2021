----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Marco D'Antini
-- 
-- Create Date: 20.02.2021 12:27:37
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is (wait_start, req_col, save_col,
                    save_row,cycle,delta, req_img_bit,comp_max,
                    comp_min,back_cycle,cycle_2,back_cycle_2, shift_state_1,
                    shift_state_2, shift_state_3, 
                    calc_new,done, wait_for_another_start);

signal state: state_type;
signal next_state: state_type;
signal min: integer range 0 to 255;
signal max: integer range 0 to 255;
signal n_col : integer range 0 to 128;
signal n_row : integer range 0 to 128;
signal tot_img_bit: integer range 0 to 16384;
signal cont: integer range 0 to 16384;
signal temp_cont: integer range 0 to 16384;
signal temp: integer range 0 to 255;
signal delta_value : integer range 0 to 255;
signal shift_level : integer range 0 to 8;
signal bit_shift : std_logic_vector(7 downto 0);
signal temp_pixel : unsigned (15 downto 0);
signal to_shift : integer range 0 to 255;



begin
    process(i_clk,i_rst)
    begin
        if i_clk'event and i_clk='1' then
            if i_rst='1' then
                next_state<=wait_start;
            else
                state<=next_state;
            end if;
            
       case state is 
       
           

           when wait_start =>
                o_done <= '0';
                bit_shift <= "00000000";
                cont<=0;
                temp_cont<= 0;
                temp<=0;
                shift_level<= 0;
                min<=255;
                max<=0; 
                if i_start = '1' then
                    next_state<= req_col;
                    
                else 
                    next_state<= wait_start;
                end if;
                
           when req_col =>
                 o_en <= '1';
                 o_we<='0';
                 o_address<=std_logic_vector(to_unsigned(0,16));  --richiedo indirizzo 0 castato a 16 bit
                 next_state<= save_col;
                 
           when save_col =>
                n_col <= to_integer(unsigned(i_data));
                o_address<=std_logic_vector(to_unsigned(1,16));
                next_state<= save_row;
                
           when save_row => 
                n_row<= to_integer(unsigned(i_data));
                tot_img_bit <= (n_col* n_row );
                next_state<= cycle;
                
           when cycle => 
                 if cont >= tot_img_bit then 
                 next_state<=delta;
                 else
                 next_state<=req_img_bit;
                 end if;
                 
           when req_img_bit =>
                o_en<='1';
                o_we<='0';
                o_address<=std_logic_vector(to_unsigned(cont+2,16));
                next_state<= comp_max;
                
           when comp_max =>
                temp <= to_integer(unsigned(i_data));
                if temp > max then 
                    max <=temp;
                    end if ;
                next_state<= comp_min;
    
                    
           when comp_min =>         
                if temp < min then
                   min <= temp;
                   end if;
                temp_cont<= cont +1; 
                next_state<= back_cycle;
                
           when back_cycle => 
               cont  <= temp_cont;
               next_state <= cycle;
               
           when delta =>               
               if  (max-min+1) = 256 then 
                    shift_level<= 0;
                    else
               bit_shift <= std_logic_vector(to_unsigned(max-min+1,8));      
                    if (bit_shift AND "10000000") =  "10000000" then
                    shift_level<= 1;
                 else if (bit_shift AND "01000000") =  "01000000" then
                    shift_level<= 2;
                 else if (bit_shift AND "00100000") =  "00100000" then
                    shift_level<= 3;
                 else if (bit_shift AND "00010000") =  "00010000" then
                    shift_level<= 4;
                 else if (bit_shift AND "00001000") =  "00001000" then
                    shift_level<= 5;
                 else if (bit_shift AND "00000100") =  "00000100" then
                    shift_level<= 6;
                 else if (bit_shift AND "00000010") =  "00000010" then
                    shift_level<= 7;
                 else if (bit_shift AND "00000001") =  "00000001" then
                    shift_level<= 8;
                    end if;
                    end if;
                    end if;
                    end if;
                    end if;
                    end if;
                    end if;
                    end if;
                    end if;
                          
                    
                    
               cont<= 0;
               temp_cont<= 0; 
               next_state <= cycle_2; 
               
           when cycle_2 =>
               --o_we <= '0';
               if cont >= tot_img_bit then 
                  next_state<=done;
               else
                  o_address<=std_logic_vector(to_unsigned(cont+2,16));
                  next_state<=shift_state_1;
               end if;
              
               
               
           when shift_state_1 =>   
                 -- ciclo in cui devo calcolare shift e scrivere new bit values  
               temp <= to_integer(unsigned(i_data));
               next_state <= shift_state_2;
                
           when shift_state_2 =>
               to_shift <= temp - min;
               next_state <= shift_state_3;
               
           when shift_state_3 =>
               temp_pixel <= shift_left(to_unsigned(to_shift,16),shift_level);
               next_state <= calc_new;
            
           when calc_new => 
                    o_address <= std_logic_vector( to_unsigned(2+tot_img_bit+cont, 16));
                    
                if 255 < to_integer(temp_pixel) then
                    o_data <= std_logic_vector( to_unsigned(255, 8));
                    else 
                    o_data <= std_logic_vector(temp_pixel(7 downto 0));
                    end if;
                    
                    o_we <= '1';
                    o_en <= '1';
                temp_cont <= cont + 1;
                next_state <= back_cycle_2;
                
            when back_cycle_2 =>
               o_we <= '0'; 
               cont  <= temp_cont; 
               next_state <= cycle_2;
                
            
            when done => 
                o_we<='0';
                o_done<='1';
                next_state <= wait_for_another_start;
                
            when wait_for_another_start =>
                if i_start = '0' then
                    next_state<= wait_start; 
                else
                    next_state <= wait_for_another_start;
                end if;
            when others =>
                next_state<= wait_start;
           end case;
         end if;
     end process;
end Behavioral;
