#requires python 3.14
import madrigalWeb.madrigalWeb as mad
import numpy as np
import folium
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.cm as mcm
import branca.colormap as cm
import webbrowser, os
import csv

print("Fetching data...")
server = mad.MadrigalData('https://cedar.openmadrigal.org')

def save_to_csv(data):
    # Save to CSV
    with open('madrigal_data.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['lat', 'lon', 'alt', 'Ne', 'kp'])
        writer.writerows(data)
    print(f"Saved {len(data)} rows to madrigal_data.csv")


day = 23
result = server.madCalculator(
    year=2026, month=1, day=day, hour=22, min=0, sec=0,
    startLat=-40, endLat=50, stepLat=10,
    startLong=-180, endLong=180, stepLong=10,
    startAlt=200, endAlt=600, stepAlt=25,   # fine altitude steps to catch the peak
    parms='Ne_iri,kp'
)
print(day)
data = np.array(result)
save_to_csv(data)

lat  = data[:, 0]
lon  = data[:, 1]
alt  = data[:, 2]
ne   = data[:, 3]
kp   = data[:, 4]

ne[ne == -1.0] = np.nan
ne = ne / 1e6 
lat_lon_pairs = np.unique(np.column_stack([lat, lon]), axis=0)

peak_ne  = []
peak_alt = []
peak_lat = []
peak_lon = []

for ll in lat_lon_pairs:
    mask = (lat == ll[0]) & (lon == ll[1])
    ne_profile = ne[mask]
    alt_profile = alt[mask]

    if np.all(np.isnan(ne_profile)):
        continue

    peak_idx = np.nanargmax(ne_profile)
    peak_ne.append(ne_profile[peak_idx])
    peak_alt.append(alt_profile[peak_idx])
    peak_lat.append(ll[0])
    peak_lon.append(ll[1])

peak_ne  = np.array(peak_ne)
peak_alt = np.array(peak_alt)
peak_lat = np.array(peak_lat)
peak_lon = np.array(peak_lon)

print(f"Peak ne range: {peak_ne.min():.2e} to {peak_ne.max():.2e}")
print(f"Peak altitude range: {peak_alt.min():.0f} to {peak_alt.max():.0f} km")

def mpl_to_branca(cmap_name, vmin, vmax, n=256):
    mpl_cmap = mcm.get_cmap(cmap_name, n)
    colors = [mcolors.to_hex(mpl_cmap(i / (n - 1))) for i in range(n)]
    return cm.LinearColormap(colors, vmin=vmin, vmax=vmax)

print(f"Array shape: {data.shape}")
print(f"NE range: {np.nanmin(ne):.2e} to {np.nanmax(ne):.2e}")
print(f"Average NE (valid points): {np.nanmean(ne):.2e}")
print(f"Valid points: {np.sum(~np.isnan(ne))} / {len(ne)}")

peak_ne_scaled = peak_ne / 1e5
valid_peak = ~np.isnan(peak_ne_scaled)

colormap = mpl_to_branca('jet', vmin=1, vmax=30)
colormap.caption = 'Peak electron density NmF2 [×10⁵ cm⁻³]'

m = folium.Map(
    location=[0, 0],
    zoom_start=2,
    tiles='CartoDB positron',
)


m.fit_bounds([[-50, -180], [50, 180]])

for lat_line in range(-90, 91, 20):
    folium.PolyLine(
        [(lat_line, lon_line) for lon_line in range(-180, 181, 1)],
        color='gray', weight=0.5, opacity=0.5
    ).add_to(m)

for lon_line in range(-180, 181, 20):
    folium.PolyLine(
        [(lat_line, lon_line) for lat_line in range(-90, 91, 1)],
        color='gray', weight=0.5, opacity=0.5
    ).add_to(m)

for i in range(len(peak_lat)):
    if np.isnan(peak_ne[i]):
        continue

    folium.CircleMarker(
        location=[peak_lat[i], peak_lon[i]],
        radius=8,
        color=colormap(peak_ne_scaled[i]),
        fill=True,
        fill_color=colormap(peak_ne_scaled[i]),
        fill_opacity=0.85,
        weight=0,
        tooltip=folium.Tooltip(
            f"NmF2: {peak_ne[i]:.3e} cm⁻³<br>"
            f"hmF2: {peak_alt[i]:.0f} km<br>"
            f"lat: {peak_lat[i]:.1f}°, lon: {peak_lon[i]:.1f}°"
        ),
        popup=folium.Popup(
            f"<b>NmF2:</b> {peak_ne[i]:.3e} cm⁻³<br>"
            f"<b>hmF2:</b> {peak_alt[i]:.0f} km<br>"
            f"<b>lat:</b> {peak_lat[i]:.1f}°<br>"
            f"<b>lon:</b> {peak_lon[i]:.1f}°",
            max_width=200
        )
    ).add_to(m)

colormap.add_to(m)


avg_nmf2 = np.nanmean(peak_ne)
avg_hmf2 = np.nanmean(peak_alt)
title_html = f"""
    <div style="position: fixed; top: 10px; left: 50%; transform: translateX(-50%);
                z-index: 1000; background: white; padding: 8px 16px;
                border-radius: 6px; border: 1px solid #ccc;
                font-size: 14px; font-family: Arial;">
        <b>IRI NmF2 — {day:02d}-01-2026 22:00 UT</b> &nbsp;|&nbsp;
        Avg NmF2: {avg_nmf2:.3e} cm⁻³ &nbsp;|&nbsp;
        Avg hmF2: {avg_hmf2:.0f} km
    </div>
"""
m.get_root().html.add_child(folium.Element(title_html))

print(f"Peak ne range: {peak_ne.min():.2e} to {peak_ne.max():.2e}")
print(f"Peak altitude range: {peak_alt.min():.0f} to {peak_alt.max():.0f} km")
print(f"Average NmF2: {avg_nmf2:.3e} cm⁻³")
print(f"Average hmF2: {avg_hmf2:.0f} km")


m.save('ne_map.html')
print("Map saved.")
webbrowser.open('file://' + os.path.abspath('ne_map.html'))