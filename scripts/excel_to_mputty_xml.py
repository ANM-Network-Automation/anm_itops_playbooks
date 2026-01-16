import pandas as pd
import xml.etree.ElementTree as ET
import uuid
import os

def excel_to_mputty_xml():
    # === Define paths ===
    script_dir = os.path.dirname(os.path.abspath(__file__))  # /project_folder/scripts
    project_root = os.path.abspath(os.path.join(script_dir, ".."))  # /project_folder

    excel_file = os.path.join(project_root, "inventory", "inventory.xlsx")  # input Excel
    output_dir = os.path.join(script_dir, "outputs")  # output directory
    output_file = os.path.join(output_dir, "mputty_inventory.xml")  # output XML

    # === Ensure output folder exists ===
    os.makedirs(output_dir, exist_ok=True)

    # === Read Excel ===
    if not os.path.exists(excel_file):
        raise FileNotFoundError(f" Excel file not found: {excel_file}")

    df = pd.read_excel(excel_file)

    # Validate required columns
    if not {'name', 'displayName'}.issubset(df.columns):
        raise ValueError("Excel must contain 'name' and 'displayName' columns")

    # === Build XML ===
    servers = ET.Element("Servers")
    putty = ET.SubElement(servers, "Putty")

    for _, row in df.iterrows():
        node = ET.SubElement(putty, "Node", Type="1")

        ET.SubElement(node, "SavedSession").text = "Default Settings"
        ET.SubElement(node, "DisplayName").text = str(row['displayName'])
        ET.SubElement(node, "UID").text = "{" + str(uuid.uuid4()).upper() + "}"
        ET.SubElement(node, "ServerName").text = str(row['name'])
        ET.SubElement(node, "PuttyConType").text = "4"  # SSH
        ET.SubElement(node, "Port").text = "0"
        ET.SubElement(node, "CLParams").text = f"{row['name']} -ssh"
        ET.SubElement(node, "ScriptDelay").text = "0"

    # === Write XML ===
    tree = ET.ElementTree(servers)
    ET.indent(tree, space="  ", level=0)
    tree.write(output_file, encoding="utf-8", xml_declaration=True)

    print(f" mPuTTY XML created successfully at:\n{output_file}")

# === Run ===
if __name__ == "__main__":
    excel_to_mputty_xml()
