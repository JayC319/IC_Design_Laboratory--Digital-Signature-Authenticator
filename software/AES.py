from Crypto.Cipher import AES

# 密碼
password = input('>>> key: ')
key = bytes.fromhex(password)

# 要加密的資料
message = input('>>> txt: ')
data = bytes.fromhex(message)

# 以金鑰搭配 CBC 模式建立 cipher 物件
cipher = AES.new(key, AES.MODE_ECB)

# 將輸入資料加上 padding 後進行加密
cipheredData = cipher.encrypt(data)
print('<<< cipher: ', cipheredData.hex())