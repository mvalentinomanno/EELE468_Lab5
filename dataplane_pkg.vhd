-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\echo4\dataplane_pkg.vhd
-- Created: 2021-03-07 17:24:45
-- 
-- Generated by MATLAB 9.9 and HDL Coder 3.17
-- 
-- -------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

PACKAGE dataplane_pkg IS
  TYPE vector_of_signed24 IS ARRAY (NATURAL RANGE <>) OF signed(23 DOWNTO 0);
END dataplane_pkg;

