import h5py
import numpy as np
import scipy.io
#requires python 3.14
with h5py.File('gps260109g.001.hdf5', 'r') as f: #download the file from the madrigal website
    data = f['/Data/Table Layout']
    mat_data = {
        'lat':  np.array(data['gdlat']),
        'lon':  np.array(data['glon']),
        'tec':  np.array(data['tec']),
        'dtec': np.array(data['dtec']),
        'hour': np.array(data['hour']),
        'min':  np.array(data['min']),
    }

scipy.io.savemat('gnss_tec.mat', mat_data)
print("Saved to gnss_tec.mat")
print(f"Total records: {len(mat_data['lat'])}")