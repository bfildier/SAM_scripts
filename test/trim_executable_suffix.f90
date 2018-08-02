program cmd_name
     character :: cmd*100, suffix*100
     integer i
     character ipos*2
     call get_command_argument(0, cmd)
     print *, "the name of the executable is : " // cmd(1:len_trim(cmd))
     i = INDEX(cmd, '_', .TRUE.)
     write (ipos, "(I2)") i
     print *, "last occurrence of character '_' occurs at index " // ipos
     suffix = cmd(i+1:)
     print *, "the corresponding suffix is : " // trim(suffix)
end program
