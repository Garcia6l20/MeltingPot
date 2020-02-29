import fileinput
import shutil
import re
import os


def main():
    os.makedirs('dist', exist_ok=True)
    shutil.copyfile('.melt_options', 'dist/.melt_options')
    shutil.copyfile('MeltingPot.cmake', 'dist/MeltingPot.cmake')
    with fileinput.FileInput('dist/MeltingPot.cmake', inplace=True) as pot_file:
        for line in pot_file:
            m = re.match(r'include\(\${CMAKE_CURRENT_LIST_DIR}/(\w+.cmake)\)',
                         line)
            if m:
                print(open(m.group(1)).read())
            else:
                print(line, end='')


if __name__ == '__main__':
    exit(main())
