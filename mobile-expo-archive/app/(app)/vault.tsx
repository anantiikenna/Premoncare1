import { useState, useCallback, useEffect } from 'react'
import { View, Text, StyleSheet, FlatList, ActivityIndicator, TouchableOpacity, RefreshControl, Linking, Alert } from 'react-native'
import * as DocumentPicker from 'expo-document-picker'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

type MedicalRecord = {
    id: string
    title: string
    record_type: string
    document_url: string
    created_at: string
}

export default function VaultScreen() {
    const { user } = useAuth()
    const [records, setRecords] = useState<MedicalRecord[]>([])
    const [loading, setLoading] = useState(true)
    const [refreshing, setRefreshing] = useState(false)
    const [uploading, setUploading] = useState(false)

    const fetchRecords = useCallback(async () => {
        if (!user) return
        try {
            const { data, error } = await supabase
                .from('medical_records')
                .select('*')
                .eq('patient_id', user.id)
                .order('created_at', { ascending: false })

            if (error) throw error
            setRecords(data as MedicalRecord[])
        } catch (error) {
            console.error('Error fetching vault records:', error)
        } finally {
            setLoading(false)
            setRefreshing(false)
        }
    }, [user])

    useEffect(() => {
        fetchRecords()
    }, [fetchRecords])

    const onRefresh = () => {
        setRefreshing(true)
        fetchRecords()
    }

    const handleUpload = async () => {
        try {
            const result = await DocumentPicker.getDocumentAsync({
                type: ['application/pdf', 'image/*'],
                copyToCacheDirectory: true
            })

            if (result.canceled) return

            setUploading(true)
            const file = result.assets[0]
            const fileExt = file.name.split('.').pop()
            const fileName = `${user?.id}/${Date.now()}.${fileExt}`

            // React Native FormData payload for Supabase
            const formData = new FormData()
            formData.append('file', {
                uri: file.uri,
                name: file.name,
                type: file.mimeType || 'application/octet-stream'
            } as any)

            const { error: uploadError } = await supabase.storage
                .from('patient-medical-vault')
                .upload(fileName, formData as any)

            if (uploadError) throw uploadError

            const { error: dbError } = await supabase.from('medical_records').insert({
                patient_id: user?.id,
                title: file.name || 'Mobile Upload',
                record_type: 'other',
                document_url: fileName
            })

            if (dbError) throw dbError

            Alert.alert('Success', 'Document securely added to your vault.')
            fetchRecords()

        } catch (error: any) {
            Alert.alert('Upload Error', error.message)
        } finally {
            setUploading(false)
        }
    }

    const viewRecord = async (record: MedicalRecord) => {
        try {
            const { data, error } = await supabase.storage.from('patient-medical-vault').createSignedUrl(record.document_url, 600)
            if (error) throw error
            if (data?.signedUrl) {
                Linking.openURL(data.signedUrl)
            }
        } catch (error: any) {
            Alert.alert('Decryption Error', error.message)
        }
    }

    const renderRecord = ({ item }: { item: MedicalRecord }) => {
        return (
            <TouchableOpacity style={styles.card} onPress={() => viewRecord(item)}>
                <View style={styles.cardIcon}>
                    <Text style={styles.iconText}>📄</Text>
                </View>
                <View style={styles.cardContent}>
                    <Text style={styles.recordTitle}>{item.title}</Text>
                    <Text style={styles.recordType}>{item.record_type.replace('_', ' ').toUpperCase()}</Text>
                    <Text style={styles.recordDate}>{new Date(item.created_at).toLocaleDateString()}</Text>
                </View>
                <View style={styles.viewBadge}>
                    <Text style={styles.viewBadgeText}>View</Text>
                </View>
            </TouchableOpacity>
        )
    }

    if (loading) {
        return (
            <View style={styles.centerParams}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        )
    }

    return (
        <View style={styles.container}>
            <View style={styles.headerInfo}>
                <Text style={styles.headerText}>Documents are securely encrypted. Only authorized practitioners can view them.</Text>
            </View>
            
            <FlatList
                data={records}
                keyExtractor={(item) => item.id}
                renderItem={renderRecord}
                contentContainerStyle={styles.list}
                refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
                ListEmptyComponent={
                    <View style={styles.emptyContainer}>
                        <Text style={styles.emptyText}>Your medical vault is empty. Upload your first document now!</Text>
                    </View>
                }
            />

            <TouchableOpacity 
                style={styles.fab} 
                onPress={handleUpload}
                disabled={uploading}
            >
                {uploading ? (
                    <ActivityIndicator color="#fff" />
                ) : (
                    <Text style={styles.fabIcon}>+</Text>
                )}
            </TouchableOpacity>
        </View>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8fafc',
    },
    centerParams: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#f8fafc',
    },
    headerInfo: {
        backgroundColor: '#eff6ff',
        padding: 16,
        borderBottomWidth: 1,
        borderBottomColor: '#dbeafe',
    },
    headerText: {
        color: '#1e40af',
        fontSize: 14,
        fontWeight: '500',
        textAlign: 'center',
    },
    list: {
        padding: 16,
        paddingBottom: 100, // Make room for FAB
    },
    card: {
        backgroundColor: '#ffffff',
        borderRadius: 16,
        padding: 16,
        marginBottom: 16,
        flexDirection: 'row',
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
    },
    cardIcon: {
        width: 48,
        height: 48,
        borderRadius: 12,
        backgroundColor: '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 16,
    },
    iconText: {
        fontSize: 20,
    },
    cardContent: {
        flex: 1,
    },
    recordTitle: {
        fontSize: 16,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 2,
    },
    recordType: {
        fontSize: 10,
        fontWeight: '800',
        color: '#2563eb',
        marginBottom: 4,
        letterSpacing: 0.5,
    },
    recordDate: {
        fontSize: 12,
        color: '#64748b',
    },
    viewBadge: {
        backgroundColor: '#f8fafc',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    viewBadgeText: {
        color: '#475569',
        fontSize: 12,
        fontWeight: '700',
    },
    emptyContainer: {
        padding: 32,
        alignItems: 'center',
    },
    emptyText: {
        color: '#64748b',
        fontSize: 15,
        textAlign: 'center',
        lineHeight: 24,
    },
    fab: {
        position: 'absolute',
        bottom: 24,
        right: 24,
        width: 64,
        height: 64,
        borderRadius: 32,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#2563eb',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.4,
        shadowRadius: 16,
        elevation: 8,
    },
    fabIcon: {
        fontSize: 32,
        color: '#ffffff',
        lineHeight: 36,
        fontWeight: '300',
    }
})
