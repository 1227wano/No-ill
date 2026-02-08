from setuptools import setup
import os

package_name = 'tts'

# 하위 폴더(espeak-ng-data 등)를 재귀적으로 찾아 data_files 형식을 만드는 함수
def package_files(directory):
    paths = []
    for (path, directories, filenames) in os.walk(directory):
        for filename in filenames:
            paths.append((os.path.join('share', package_name, path), [os.path.join(path, filename)]))
    return paths

extra_files = package_files('models')

setup(
    name=package_name,
    version='0.0.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ] + extra_files, # models 폴더 내의 모든 파일과 하위 폴더 구조를 포함
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='jetson',
    description='TTS Node with recursive model directory copy',
    license='Apache License 2.0',
    entry_points={
        'console_scripts': [
            'tts_node = tts.tts_node:main'
        ],
    },
)