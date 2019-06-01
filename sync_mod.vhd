library IEEE;
 use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.STD_LOGIC_ARITH.ALL;
 use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sync_mod is
       Port ( clk         : in  STD_LOGIC;
		        clk1        : out  STD_LOGIC;
                 reset      : in  STD_LOGIC;
                 basla     : in  STD_LOGIC;
                 y_sayac : out  STD_LOGIC_VECTOR (9 downto 0);
                 x_sayac  : out  STD_LOGIC_VECTOR (9 downto 0);
                 h_s          : out  STD_LOGIC;
                 v_s           : out  STD_LOGIC;
                video_on : out  STD_LOGIC);
end sync_mod;

architecture Behavioral of sync_mod is
-- video parametreleri
constant HGO:integer:=640;--Yatay görüntü
constant HFP:integer:=16;--Horizontal Front Porch 
constant HBP:integer:=48;--Horizontal Back Porch
constant HGK:integer:=96;--Yatay geri kayma
constant VGO:integer:=480;--Düşey görüntü
constant VFP:integer:=10;--Vertical Front Porch 
constant VBP:integer:=33;--Vertical Back Porch
constant VGK:integer:=2;--Düşey geri kayma
--sync sayacları
signal count_h,count_h_next: integer range 0 to 799;
signal count_v,count_v_next: integer range 0 to 524;
--mod 2 sayac
signal sayac_mod2,sayac_mod2_next: std_logic:='0';
--durum sinyalleri
signal h_end, v_end:std_logic:='0';
--çıkış sinyalleri(buffer)
signal hs_buffer,hs_buffer_next:std_logic:='0';
signal vs_buffer,vs_buffer_next:std_logic:='0';
--piksel sayaclar
signal x_say, x_say_next:integer range 0 to 900;
signal y_say, y_say_next:integer range 0 to 900;
--video_on_of
signal video:std_logic;
begin
--register
    process(clk,reset,basla)
        begin
           if reset ='1' then
               count_h<=0;
               count_v<=0;
               hs_buffer<='0';
               hs_buffer<='0';
               sayac_mod2<='0';
          elsif clk'event and clk='1' and basla = '1' then
               count_h<=count_h_next;
               count_v<=count_v_next;
                x_say<=x_say_next;
                y_say<=y_say_next;
                hs_buffer<=hs_buffer_next;
                vs_buffer<=vs_buffer_next;
                sayac_mod2<=sayac_mod2_next;
         end if;
end process;
--video on/off
        video <= '1' when  (count_v >= VBP) and (count_v < VBP + VGO) and (count_h >=HBP) and (count_h < HBP + HGO) 
                              else 
                          '0'; 

--mod 2 sayac
        clk1<=sayac_mod2;
        sayac_mod2_next<=not sayac_mod2;
-- Yatay taramanın bitmesi
        h_end<= '1' when count_h=799 else --(HGO+HFP+HBP+HGK-1)
                          '0';        
-- düşey taramanın bitmesi
       v_end<= '1' when count_v=524 else --(VGO+VFP+VBP+VGK-1)
                       '0';  
-- Yatay sayac
process(count_h,sayac_mod2,h_end)
     begin
        count_h_next<=count_h;
        if  sayac_mod2= '1' then
            if h_end='1' then
                count_h_next<=0;
            else
                count_h_next<=count_h+1;
           end if;
      end if;
   end process;

-- Düşey sayac
process(count_v,sayac_mod2,h_end,v_end)
    begin         
       count_v_next <= count_v;
       if  sayac_mod2= '1' and h_end='1'  then
          if v_end='1' then
              count_v_next<=0;
          else
               count_v_next<=count_v+1;
          end if;
        end if;
    end process;

--piksel x sayac
process(x_say,sayac_mod2,h_end,video)
     begin        
        x_say_next<=x_say;
        if video = '1' then 
            if  sayac_mod2= '1' then                             
                if x_say= 639 then
                    x_say_next<=0;
                else
                   x_say_next<=x_say + 1;
              end if;
          end if;
     else
        x_say_next<=0;
    end if;
end process;

--pixsel y sayac
process(y_say,sayac_mod2,h_end,count_v)
     begin         
        y_say_next<=y_say;
        if  sayac_mod2= '1' and h_end='1' then 
           if count_v >32 and count_v <512  then
               y_say_next<=y_say + 1;
          else 
              y_say_next<=0;                            
          end if;
      end if;
end process;

--buffer
 hs_buffer_next<= '1' when count_h < 704 else --(HBP+HGO+HFP) 
                                  '0';
 vs_buffer_next<='1' when count_v < 523 else --(VBP+VGO+VFP) 
                                '0';       

 --çıkışlar
 y_sayac <= conv_std_logic_vector(y_say,10); 
 x_sayac <= conv_std_logic_vector(x_say,10); 
 h_s<= hs_buffer;
 v_s<= vs_buffer;
 video_on<=video;

end Behavioral;

 

