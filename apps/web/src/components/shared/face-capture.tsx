'use client'

import { useRef, useState, useCallback, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Camera, RefreshCw, CheckCircle2, ShieldAlert, Loader2, ScanFace } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

interface FaceCaptureProps {
    onCapture: (blob: Blob) => void
    isProcessing?: boolean
}

export function FaceCapture({ onCapture, isProcessing }: FaceCaptureProps) {
    const videoRef = useRef<HTMLVideoElement>(null)
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const [image, setImage] = useState<string | null>(null)
    const [isCameraReady, setIsCameraReady] = useState(false)
    const [stream, setStream] = useState<MediaStream | null>(null)
    const [error, setError] = useState<string | null>(null)

    const stopCamera = useCallback((currentStream: MediaStream | null) => {
        if (currentStream) {
            currentStream.getTracks().forEach(track => track.stop())
            setStream(null)
        }
    }, [])

    const startCamera = useCallback(async () => {
        try {
            const s = await navigator.mediaDevices.getUserMedia({ 
                video: { width: 640, height: 640, facingMode: 'user' },
                audio: false 
            })
            setStream(s)
            if (videoRef.current) {
                videoRef.current.srcObject = s
                setIsCameraReady(true)
            }
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : 'Camera Access Denied'
            setError(msg)
        }
    }, [])

    useEffect(() => {
        startCamera()
        return () => {
            setStream(prev => {
                if (prev) prev.getTracks().forEach(track => track.stop())
                return null
            })
        }
    }, [startCamera])

    const handleCapture = useCallback(() => {
        if (videoRef.current && canvasRef.current) {
            const canvas = canvasRef.current
            const video = videoRef.current
            canvas.width = video.videoWidth
            canvas.height = video.videoHeight
            const ctx = canvas.getContext('2d')
            if (ctx) {
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
                const imageSrc = canvas.toDataURL('image/jpeg')
                setImage(imageSrc)
                
                canvas.toBlob((blob) => {
                    if (blob) onCapture(blob)
                }, 'image/jpeg')
                
                stopCamera(stream)
            }
        }
    }, [onCapture, stream, stopCamera])

    const resetCapture = () => {
        setImage(null)
        setError(null)
        startCamera()
    }

    return (
        <div className="relative w-full max-w-md mx-auto aspect-square overflow-hidden rounded-3xl border-4 border-primary/20 shadow-2xl flex flex-col items-center justify-center bg-slate-900 group">
            <canvas ref={canvasRef} className="hidden" />
            
            {/* Scanning Overlay Effect */}
            {!image && isCameraReady && (
                <div className="absolute inset-0 pointer-events-none z-10">
                    <div className="absolute inset-0 bg-black/40" style={{
                        maskImage: 'radial-gradient(ellipse 40% 50% at 50% 50%, transparent 95%, black 100%)',
                        WebkitMaskImage: 'radial-gradient(ellipse 40% 50% at 50% 50%, transparent 95%, black 100%)'
                    }} />
                    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[60%] h-[75%] border-2 border-primary/50 rounded-[100%] border-dashed animate-pulse">
                        <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary px-3 py-1 rounded-full text-[8px] font-black text-white uppercase tracking-widest">
                            Align Face Here
                        </div>
                    </div>
                    <div className="h-0.5 w-full bg-primary/20 absolute top-1/2 animate-scan" />
                </div>
            )}

            {!image ? (
                <>
                    <video
                        ref={videoRef}
                        autoPlay
                        playsInline
                        muted
                        className="w-full h-full object-cover rounded-2xl"
                    />
                    
                    <div className="absolute bottom-6 left-0 right-0 px-6 flex justify-center z-20">
                        {error ? (
                            <div className="bg-red-50 text-red-600 p-3 rounded-xl flex items-center gap-2 text-xs font-bold border border-red-100">
                                <ShieldAlert className="h-4 w-4" />
                                {error}
                            </div>
                        ) : (
                            <Button 
                                size="lg" 
                                className="rounded-full w-16 h-16 bg-white hover:bg-slate-100 text-primary shadow-xl ring-4 ring-primary/20 p-0"
                                onClick={handleCapture}
                                disabled={!isCameraReady}
                            >
                                <Camera className="h-8 w-8" />
                            </Button>
                        )}
                    </div>

                    <div className="absolute top-6 left-6 z-20">
                        <Badge variant="secondary" className="bg-black/60 text-white backdrop-blur-md border-0 px-3 py-1 flex items-center gap-2">
                           <ScanFace className="h-3 w-3 animate-pulse text-primary" />
                           Face Detection Active
                        </Badge>
                    </div>
                </>
            ) : (
                <div className="relative w-full h-full animate-in zoom-in duration-300">
                    <img 
                        src={image} 
                        alt="Captured Face" 
                        className="w-full h-full object-cover blur-[1px] opacity-80" 
                    />
                    <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/40 backdrop-blur-sm p-4 text-center">
                        {isProcessing ? (
                            <div className="space-y-4">
                                <div className="relative mx-auto w-16 h-16">
                                    <div className="absolute inset-0 border-4 border-primary/20 rounded-full" />
                                    <div className="absolute inset-0 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                                    <ScanFace className="absolute inset-0 m-auto h-8 w-8 text-white" />
                                </div>
                                <div className="space-y-1">
                                    <p className="text-white font-black text-lg">Analyzing Bio-metrics</p>
                                    <p className="text-white/60 text-xs">Matching face with ID document...</p>
                                </div>
                            </div>
                        ) : (
                            <div className="space-y-6">
                                <div className="bg-green-500 p-4 rounded-full w-16 h-16 mx-auto flex items-center justify-center shadow-xl shadow-green-500/20">
                                    <CheckCircle2 className="h-10 w-10 text-white" />
                                </div>
                                <div className="space-y-1">
                                    <p className="text-white font-black text-xl tracking-tight">Capture Confirmed</p>
                                    <p className="text-white/60 text-sm">Face biometric recorded successfully</p>
                                </div>
                                <Button 
                                    variant="outline" 
                                    size="sm" 
                                    className="bg-white/10 border-white/20 text-white hover:bg-white/20 rounded-full h-10 px-6 backdrop-blur-xl"
                                    onClick={resetCapture}
                                >
                                    <RefreshCw className="mr-2 h-4 w-4" />
                                    Retake Photo
                                </Button>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    )
}
