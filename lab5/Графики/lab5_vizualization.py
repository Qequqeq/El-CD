import matplotlib.pyplot as plt
import numpy as np


def q16_16_to_float(bin_str: str) -> float:
    val = int(bin_str, 2)
    if val & (1 << 31):
        val -= (1 << 32)
    return val / 65536.0

def load_data(filename):
    x, y, z, t = [], [], [], []
    with open(filename, 'r') as f:
        f.readline()  # заголовок
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split(';')
            if len(parts) != 4:
                continue
            x_bin, y_bin, z_bin, t_bin = parts
            x.append(q16_16_to_float(x_bin))
            y.append(q16_16_to_float(y_bin))
            z.append(q16_16_to_float(z_bin))
            t.append(q16_16_to_float(t_bin))
    return np.array(x), np.array(y), np.array(z), np.array(t)

def plot_time_series(t, data, label, color='black', title=None):
    """
    Построение временного ряда на отдельной фигуре.
    t -- массив времени,
    data -- массив данных,
    label -- название оси,
    color -- цвет линии,
    title -- заголовок
    """
    plt.figure(figsize=(12, 8))
    plt.plot(t, data, color=color, lw=0.8)
    plt.xlabel('Время (сек)')
    plt.ylabel(label)
    if title:
        plt.title(title)
    else:
        plt.title(f'{label}(t)')
    plt.grid(True, alpha=0.3)

    plt.show()

def plot_phase_portrait(data1, data2, label1, label2, color='black', title=None):
    """
    data1, data2 -- массивы координат,
    label1, label2 -- названия осей,
    color -- цвет линии,
    title -- заголовок
    """
    plt.figure(figsize=(12, 8))
    plt.plot(data1, data2, color=color, lw=0.8)
    plt.xlabel(label1)
    plt.ylabel(label2)
    if title:
        plt.title(title)
    else:
        plt.title(f'Фазовый портрет ({label1}, {label2})')
    plt.axis('equal')

    plt.show()

def plot_3d_trajectory(x, y, z, t, step=1):
    """
    Построение 3D траектории (x, y, z) с цветовой кодировкой времени.
    step — прореживание точек для ускорения отрисовки.
    """
    t_subsampled = t[::step]
    x_subsampled = x[::step]
    y_subsampled = y[::step]
    z_subsampled = z[::step]

    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection='3d')

    ax.plot(x_subsampled, y_subsampled, z_subsampled, 'b-', lw=0.5, alpha=0.7)

    sc = ax.scatter(x_subsampled, y_subsampled, z_subsampled, c=t_subsampled, cmap='viridis', s=1, alpha=0.6)
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    ax.set_title('3D траектория (x, y, z)')
    cbar = plt.colorbar(sc, ax=ax)
    cbar.set_label('Время')
    plt.show()

def main():
    file_path = "/home/kniv/Загрузки/output.txt"
    x, y, z, t = load_data(file_path)

    plot_time_series(t, x, 'x', title='Временной ряд x(t)')
    plot_time_series(t, y, 'y', title='Временной ряд y(t)')
    plot_time_series(t, z, 'z', title='Временной ряд z(t)')

    plot_phase_portrait(x, y, 'x', 'y')
    plot_phase_portrait(x, z, 'x', 'z')
    plot_phase_portrait(y, z, 'y', 'z')

    plot_3d_trajectory(x, y, z, t)






if __name__ == "__main__":
    main()