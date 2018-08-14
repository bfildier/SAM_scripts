program cmd_name
     character :: cmd*100, suffix*100
     integer i,j
     character ipos*2,jpos*2
     call get_command_argument(0, cmd)
     print *, "the name of the executable is : " // cmd(1:len_trim(cmd))
     i = INDEX(cmd, '_', .TRUE.)
     j = LEN_TRIM(cmd)
     write (ipos, "(I2)") i
     write (jpos, "(I2)") j
     print *, "last occurrence of character '_' occurs at index " // ipos
     print *, "length of string is " // jpos
     suffix = cmd(i+1:j)
     print *, "the corresponding suffix is : " // trim(suffix)
end program
