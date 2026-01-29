from setuptools import find_packages, setup
import os
from glob import glob

package_name = 'stt'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name), ['stt/hotwords.txt']),
        # Launch 파일이나 설정 파일을 추가할 경우를 대비한 설정
        (os.path.join('share', package_name, 'launch'), glob('launch/*.py')),
    ],
    install_requires=[
        'setuptools',
        'sherpa-onnx',
        'sounddevice',
        'numpy'
    ],
    zip_safe=True,
    maintainer='jetson',
    maintainer_email='jetson@todo.todo',
    description='ROS2 STT node using sherpa-onnx Zipformer',
    license='Apache-2.0',
    extras_require={
        'test': [
            'pytest',
        ],
    },
    entry_points={
        'console_scripts': [
            # 실행파일명 = 패키지명.파일명:함수명
            'stt_node = stt.stt_node:main'
        ],
    },
)
